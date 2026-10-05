/** Local-only adapter behind Tailscale Serve; DSH credentials never reach clients. */
import http from "node:http";
import { open } from "node:fs/promises";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { pipeline } from "node:stream";
import { pathToFileURL } from "node:url";

const HOP_HEADERS = ["connection", "keep-alive", "proxy-authenticate", "proxy-authorization", "te", "trailer", "transfer-encoding", "upgrade"];
const SECRET_QUERY = /^(?:token|access_token|refresh_token|id_token)$/i;

function headersWithoutHop(headers) {
  const result = { ...headers };
  for (const name of String(headers.connection ?? "").split(",")) delete result[name.trim().toLowerCase()];
  for (const name of HOP_HEADERS) delete result[name];
  return result;
}

function authority(value) {
  if (typeof value !== "string" || /[\s/@?#]/.test(value)) return undefined;
  try {
    const url = new URL(`https://${value}`);
    if (url.username || url.password || url.pathname !== "/") return undefined;
    return url.host;
  } catch {
    return undefined;
  }
}

function reject(response, status) {
  if (response.destroyed) return;
  if (response.headersSent) return response.destroy();
  response.writeHead(status, { "content-type": "text/plain; charset=utf-8", "cache-control": "no-store" });
  response.end(status === 403 ? "Forbidden\n" : status === 400 ? "Invalid request\n" : "DSH temporarily unavailable\n");
}

function rejectUpgrade(socket, status) {
  if (!socket.destroyed) socket.end(`HTTP/1.1 ${status} ${http.STATUS_CODES[status]}\r\nConnection: close\r\nContent-Length: 0\r\n\r\n`);
}

function requestTarget(request, hosts, upstream) {
  const host = authority(request.headers.host);
  if (!hosts.has(host) || request.headers["sec-fetch-site"] === "cross-site") return { rejection: 403 };
  if (request.headers.origin !== undefined) {
    let origin;
    try { origin = new URL(request.headers.origin); } catch { return { rejection: 403 }; }
    if (!["http:", "https:"].includes(origin.protocol) || authority(origin.host) !== host || origin.username || origin.password || origin.pathname !== "/" || origin.search || origin.hash) return { rejection: 403 };
  }
  if (!request.url?.startsWith("/") || request.url.startsWith("//")) return { rejection: 400 };
  let target;
  try { target = new URL(request.url, upstream); } catch { return { rejection: 400 }; }
  // WHATWG URLs treat backslashes as slashes: /\\host is also a network path.
  if (target.origin !== upstream.origin || target.username || target.password) return { rejection: 400 };
  if ([...target.searchParams.keys()].some((key) => SECRET_QUERY.test(key))) return { rejection: 400 };
  return { target };
}

function backendHeaders(request, upstream, cookie) {
  const headers = headersWithoutHop(request.headers);
  delete headers.authorization;
  delete headers["x-dsh-auth-token"];
  headers.host = upstream.host;
  headers.cookie = cookie;
  if (headers.origin !== undefined) headers.origin = upstream.origin;
  // Forwarding identities are not accepted as authentication by the backend.
  for (const name of Object.keys(headers)) if (name.startsWith("tailscale-") || name.startsWith("x-forwarded-") || name === "forwarded") delete headers[name];
  return headers;
}

/** Read a bounded private log tail without exposing any matched URL. */
async function startupUrl(logPath, upstream) {
  const file = await open(logPath, "r");
  try {
    const { size } = await file.stat();
    const length = Math.min(size, 4 * 1024 * 1024);
    const buffer = Buffer.alloc(length);
    const { bytesRead } = await file.read(buffer, 0, length, size - length);
    const matches = [...buffer.subarray(0, bytesRead).toString("utf8").matchAll(/^dsh web: (http:\/\/127\.0\.0\.1:\d+\/\?token=[A-Za-z0-9_-]+)(?:\s|$)/gm)];
    for (const match of matches.reverse()) {
      const url = new URL(match[1]);
      if (url.origin === upstream.origin) return url;
    }
    throw new Error("Startup URL unavailable");
  } finally {
    await file.close();
  }
}

/** Bounded authentication probe; response values remain private to this process. */
function probe(url, method, cookie) {
  return new Promise((resolveProbe, rejectProbe) => {
    const request = http.request(url, { method, headers: cookie ? { cookie } : {} }, (response) => {
      const result = { status: response.statusCode, headers: response.headers };
      response.resume();
      response.on("end", () => resolveProbe(result));
      response.on("error", () => rejectProbe(new Error("Authentication probe failed")));
    });
    request.setTimeout(5000, () => request.destroy(new Error("Authentication probe timeout")));
    request.on("error", () => rejectProbe(new Error("Authentication probe failed")));
    request.end();
  });
}

function authenticator(logPath, upstream) {
  let cookie;
  let pending;
  async function ensure() {
    if (pending) return pending;
    pending = (async () => {
      if (cookie) {
        const result = await probe(upstream, "HEAD", cookie);
        if (result.status === 200) return cookie;
        if (result.status !== 401) throw new Error("Backend unavailable");
        cookie = undefined;
      }
      const result = await probe(await startupUrl(logPath, upstream), "GET");
      const cookies = result.headers["set-cookie"] ?? [];
      const authCookie = cookies.map((value) => value.split(";", 1)[0]).find((value) => /^dsh-auth-[A-Za-z0-9_-]+=[A-Za-z0-9_.-]+$/.test(value));
      if (result.status !== 303 || result.headers.location !== "./" || !authCookie) throw new Error("Authentication unavailable");
      cookie = authCookie;
      return cookie;
    })();
    try { return await pending; } finally { pending = undefined; }
  }
  return {
    ensure,
    invalidate(value) { if (cookie === value) cookie = undefined; },
  };
}

/** Defaults must only be exposed by Tailscale Serve, never a public/LAN listener. */
export function createTailnetProxy({
  upstream: upstreamValue = "http://127.0.0.1:3080",
  logPath = join(homedir(), ".local/state/dsh/web.log"),
  allowedHosts = ["lelouch.tail1afda.ts.net"],
} = {}) {
  const upstream = new URL(upstreamValue);
  if (upstream.protocol !== "http:" || upstream.hostname !== "127.0.0.1" || upstream.username || upstream.password || upstream.pathname !== "/" || upstream.search || upstream.hash) throw new Error("Backend must be a loopback HTTP origin");
  const hosts = new Set(allowedHosts.map(authority));
  if (!hosts.size || hosts.has(undefined)) throw new Error("Invalid allowed host");
  const auth = authenticator(logPath, upstream);
  const upgradedSockets = new Set();

  const server = http.createServer(async (request, response) => {
    const admission = requestTarget(request, hosts, upstream);
    if (admission.rejection) return reject(response, admission.rejection);
    const { target } = admission;

    async function forward(retry = false) {
      const cookie = await auth.ensure();
      if (request.aborted || response.destroyed) return;
      const headers = backendHeaders(request, upstream, cookie);

      const backend = http.request(target, { method: request.method, headers }, (incoming) => {
        if (incoming.statusCode === 401) {
          incoming.on("error", () => {});
          incoming.resume();
          auth.invalidate(cookie);
          // A consumed upload or mutating request must never be replayed automatically.
          if (!retry && ["GET", "HEAD"].includes(request.method)) {
            forward(true).catch(() => reject(response, 503));
          } else {
            auth.ensure().catch(() => {});
            reject(response, 503);
          }
          return;
        }
        const outgoing = headersWithoutHop(incoming.headers);
        delete outgoing["set-cookie"];
        delete outgoing["set-cookie2"];
        if (outgoing.location) {
          let location;
          try { location = new URL(outgoing.location, upstream); } catch { incoming.destroy(); return reject(response, 502); }
          if (location.origin !== upstream.origin || [...location.searchParams.keys()].some((key) => SECRET_QUERY.test(key))) {
            incoming.destroy();
            return reject(response, 502);
          }
          outgoing.location = `${location.pathname}${location.search}${location.hash}`;
        }
        response.writeHead(incoming.statusCode ?? 502, outgoing);
        response.flushHeaders();
        pipeline(incoming, response, () => {});
      });
      backend.on("error", () => reject(response, 502));
      // Bound connection establishment only: RPCs and SSE can legitimately run much longer.
      const timeout = setTimeout(() => backend.destroy(new Error("Backend connection timeout")), 5000);
      timeout.unref();
      backend.once("socket", (socket) => {
        if (socket.connecting) socket.once("connect", () => clearTimeout(timeout));
        else clearTimeout(timeout);
      });
      backend.once("error", () => clearTimeout(timeout));
      const cancel = () => backend.destroy();
      request.once("aborted", cancel);
      response.once("close", cancel);
      backend.once("close", () => {
        request.off("aborted", cancel);
        response.off("close", cancel);
      });
      if (retry) backend.end();
      else {
        request.once("error", cancel);
        request.pipe(backend);
      }
    }
    try { await forward(); } catch { reject(response, 503); }
  });
  server.on("upgrade", async (request, socket, head) => {
    const admission = requestTarget(request, hosts, upstream);
    if (admission.rejection) return rejectUpgrade(socket, admission.rejection);
    if (request.method !== "GET" || request.headers.upgrade?.toLowerCase() !== "websocket") return rejectUpgrade(socket, 400);
    socket.pause();
    socket.on("error", () => socket.destroy());
    async function upgrade(retry = false) {
      const cookie = await auth.ensure();
      if (socket.destroyed) return;
      const headers = backendHeaders(request, upstream, cookie);
      headers.connection = "Upgrade";
      headers.upgrade = "websocket";
      const backend = http.request(admission.target, { method: "GET", headers });
      const timeout = setTimeout(() => backend.destroy(new Error("Upgrade timeout")), 10000);
      timeout.unref();
      const clientClosed = () => backend.destroy();
      socket.once("close", clientClosed);
      function cleanup() { clearTimeout(timeout); socket.off("close", clientClosed); }
      backend.once("upgrade", (incoming, upstreamSocket, upstreamHead) => {
        cleanup();
        if (socket.destroyed) return upstreamSocket.destroy();
        // Emit only handshake headers; backend authentication stays entirely internal.
        const outgoing = { connection: "Upgrade", upgrade: "websocket" };
        for (const name of ["sec-websocket-accept", "sec-websocket-protocol", "sec-websocket-extensions"]) {
          if (typeof incoming.headers[name] === "string") outgoing[name] = incoming.headers[name];
        }
        socket.write(`HTTP/1.1 101 Switching Protocols\r\n${Object.entries(outgoing).map(([name, value]) => `${name}: ${value}\r\n`).join("")}\r\n`);
        if (upstreamHead.length) socket.write(upstreamHead);
        if (head.length) upstreamSocket.write(head);
        upgradedSockets.add(socket);
        const close = () => { upgradedSockets.delete(socket); socket.destroy(); upstreamSocket.destroy(); };
        socket.once("close", close);
        upstreamSocket.once("close", close);
        socket.once("error", close);
        upstreamSocket.once("error", close);
        socket.pipe(upstreamSocket);
        upstreamSocket.pipe(socket);
        socket.resume();
      });
      backend.once("response", (incoming) => {
        cleanup();
        incoming.on("error", () => {});
        incoming.resume();
        if (incoming.statusCode === 401 && !retry) {
          auth.invalidate(cookie);
          upgrade(true).catch(() => rejectUpgrade(socket, 503));
        } else rejectUpgrade(socket, incoming.statusCode === 401 ? 503 : 502);
      });
      backend.once("error", () => { cleanup(); rejectUpgrade(socket, 502); });
      backend.end();
    }
    try { await upgrade(); } catch { rejectUpgrade(socket, 503); }
  });
  // Node's ordinary close helpers do not include upgraded sockets.
  const originalClose = server.close.bind(server);
  server.close = (...args) => {
    for (const socket of upgradedSockets) socket.destroy();
    return originalClose(...args);
  };
  server.on("clientError", (_error, socket) => socket.end("HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n"));
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  const port = Number(process.env.DSH_PROXY_PORT ?? 3081);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error("Invalid proxy port");
  const server = createTailnetProxy({
    allowedHosts: [process.env.DSH_TAILNET_HOST ?? "lelouch.tail1afda.ts.net"],
    logPath: process.env.DSH_WEB_LOG ?? join(homedir(), ".local/state/dsh/web.log"),
  });
  server.on("error", () => { console.error("DSH tailnet proxy failed"); process.exitCode = 1; });
  server.listen(port, "127.0.0.1");
  for (const signal of ["SIGINT", "SIGTERM"]) process.on(signal, () => server.close(() => process.exit(0)));
}
