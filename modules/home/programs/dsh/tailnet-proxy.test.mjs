import test from "node:test";
import assert from "node:assert/strict";
import http from "node:http";
import { mkdtemp, writeFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { once } from "node:events";
import { createHash } from "node:crypto";
import { createTailnetProxy } from "./tailnet-proxy.mjs";

const HOST = "lelouch.tail1afda.ts.net";
async function listen(server) { server.listen(0, "127.0.0.1"); await once(server, "listening"); return `http://127.0.0.1:${server.address().port}`; }
async function stop(server) { if (!server.listening) return; const closed = once(server, "close"); server.close(); server.closeAllConnections(); await closed; }
function get(url, { method = "GET", path = "/", headers = {}, body } = {}) {
  return new Promise((resolve, reject) => {
    const request = http.request(url, { path, method, headers: { host: HOST, ...headers } }, (response) => {
      const chunks = [];
      response.on("data", (chunk) => chunks.push(chunk));
      response.on("end", () => resolve({ status: response.statusCode, headers: response.headers, body: Buffer.concat(chunks).toString() }));
      response.on("error", reject);
    });
    request.on("error", reject);
    request.end(body);
  });
}
function websocket(url, { path = "/api/remote.mux", headers = {} } = {}) {
  return new Promise((resolve, reject) => {
    const request = http.request(url, { path, headers: {
      host: HOST, origin: `https://${HOST}`, connection: "Upgrade", upgrade: "websocket",
      "sec-websocket-version": "13", "sec-websocket-key": "dGhlIHNhbXBsZSBub25jZQ==", ...headers,
    } });
    request.on("upgrade", (response, socket, head) => resolve({ status: response.statusCode, headers: response.headers, socket, head }));
    request.on("response", (response) => { response.resume(); resolve({ status: response.statusCode }); });
    request.on("error", reject);
    request.end();
  });
}
function maskedFrame(text) {
  const body = Buffer.from(text);
  const mask = Buffer.from([1, 2, 3, 4]);
  return Buffer.concat([Buffer.from([0x81, 0x80 | body.length]), mask, Buffer.from(body.map((value, index) => value ^ mask[index % 4]))]);
}

test("tailnet proxy authenticates privately and streams with browser fences", { timeout: 10000 }, async (t) => {
  const directory = await mkdtemp(join(tmpdir(), "dsh-tailnet-test-"));
  const logPath = join(directory, "web.log");
  let generation = 1;
  let exchanges = 0;
  let calls = 0;
  let mutatingCalls = 0;
  let upgrades = 0;
  let rotateUpgrade = false;
  const backendSockets = new Set();
  let forceRotation = false;
  let upstream;
  async function updateLog() { await writeFile(logPath, `dsh web: ${upstream}/?token=fixture-${generation}\n`, { mode: 0o600 }); }
  const backend = http.createServer(async (request, response) => {
    calls++;
    if (request.method === "POST") mutatingCalls++;
    assert.equal(request.headers.host, new URL(upstream).host);
    const url = new URL(request.url, upstream);
    if (url.searchParams.get("token") === `fixture-${generation}`) {
      exchanges++;
      response.writeHead(303, { location: "./", "set-cookie": `dsh-auth-test=fixture-cookie-${generation}; HttpOnly; SameSite=Strict` });
      return response.end();
    }
    if (url.pathname === "/rotate" && forceRotation) {
      forceRotation = false;
      generation++;
      await updateLog();
    }
    if (request.headers.cookie !== `dsh-auth-test=fixture-cookie-${generation}`) { response.writeHead(401); return response.end("unauthorized"); }
    if (url.pathname === "/api/events") {
      assert.equal(request.headers.origin, upstream);
      response.writeHead(200, { "content-type": "text/event-stream", "set-cookie": "never-expose=fixture" });
      response.write("data: first\n\n");
      return setTimeout(() => response.end("data: second\n\n"), 150);
    }
    if (url.pathname === "/api/upload") {
      let size = 0;
      for await (const chunk of request) size += chunk.length;
      response.end(JSON.stringify({ size }));
      return;
    }
    if (url.pathname === "/bad-redirect") { response.writeHead(303, { location: `/?token=fixture-${generation}` }); return response.end(); }
    response.writeHead(200, { "content-type": "text/html" });
    response.end(request.method === "HEAD" ? undefined : "DeepSeek Harness");
  });
  backend.on("upgrade", async (request, socket, head) => {
    upgrades++;
    backendSockets.add(socket);
    socket.once("close", () => backendSockets.delete(socket));
    socket.on("error", () => socket.destroy());
    if (rotateUpgrade) { rotateUpgrade = false; generation++; await updateLog(); }
    if (request.headers.cookie !== `dsh-auth-test=fixture-cookie-${generation}`) return socket.end("HTTP/1.1 401 Unauthorized\r\nContent-Length: 0\r\n\r\n");
    assert.equal(request.headers.origin, upstream);
    assert.equal(request.headers.host, new URL(upstream).host);
    const accept = createHash("sha1").update(request.headers["sec-websocket-key"] + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").digest("base64");
    const ready = Buffer.from([0x81, 5, ...Buffer.from("ready")]);
    socket.write(Buffer.concat([Buffer.from(`HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: ${accept}\r\nSet-Cookie: fixture-upgrade=secret\r\n\r\n`), ready]));
    let pending = head;
    const receive = (chunk) => {
      pending = Buffer.concat([pending, chunk]);
      while (pending.length >= 6 && pending.length >= 6 + (pending[1] & 127)) {
        const length = pending[1] & 127;
        const payload = Buffer.from(pending.subarray(6, 6 + length).map((value, index) => value ^ pending[2 + index % 4]));
        pending = pending.subarray(6 + length);
        socket.write(Buffer.concat([Buffer.from([0x81, length]), payload]));
      }
    };
    socket.on("data", receive);
    if (head.length) receive(Buffer.alloc(0));
  });
  upstream = await listen(backend);
  await updateLog();
  const proxy = createTailnetProxy({ upstream, logPath });
  const proxyUrl = await listen(proxy);
  t.after(async () => { await stop(proxy); for (const socket of backendSockets) socket.destroy(); await stop(backend); await rm(directory, { recursive: true, force: true }); });

  await t.test("fresh browser needs no token and receives no backend cookie", async () => {
    const result = await get(proxyUrl);
    assert.equal(result.status, 200);
    assert.equal(result.body, "DeepSeek Harness");
    assert.equal(result.headers["set-cookie"], undefined);
    assert.equal(exchanges, 1);
  });
  await t.test("SSE reaches client before upstream completion", async () => {
    await new Promise((resolve, reject) => {
      const request = http.get(`${proxyUrl}/api/events`, { headers: { host: HOST, origin: `https://${HOST}`, "sec-fetch-site": "same-origin" } }, (response) => {
        assert.equal(response.statusCode, 200);
        assert.equal(response.headers["set-cookie"], undefined);
        let first = true;
        let body = "";
        response.on("data", (chunk) => { if (first) { assert.equal(chunk.toString(), "data: first\n\n"); first = false; } body += chunk; });
        response.on("end", () => { assert.equal(body, "data: first\n\ndata: second\n\n"); resolve(); });
        response.on("error", reject);
      });
      request.on("error", reject);
    });
  });
  await t.test("streaming API upload preserves bytes", async () => {
    const body = "a".repeat(1024 * 1024);
    const result = await get(proxyUrl, { path: "/api/upload", method: "POST", body, headers: { origin: `https://${HOST}` } });
    assert.equal(result.status, 200);
    assert.equal(JSON.parse(result.body).size, body.length);
  });
  await t.test("401 after preflight refreshes rotated token once", async () => {
    forceRotation = true;
    const result = await get(proxyUrl, { path: "/rotate" });
    assert.equal(result.status, 200);
    assert.equal(exchanges, 2);
  });
  await t.test("restart before request refreshes cached cookie", async () => {
    generation++;
    await updateLog();
    assert.equal((await get(proxyUrl)).status, 200);
    assert.equal(exchanges, 3);
  });
  await t.test("401 race never replays a mutating body", async () => {
    forceRotation = true;
    const before = mutatingCalls;
    const result = await get(proxyUrl, { path: "/rotate", method: "POST", body: "do-once" });
    assert.equal(result.status, 503);
    assert.equal(mutatingCalls, before + 1);
    assert.equal((await get(proxyUrl)).status, 200);
  });
  await t.test("untrusted browser requests never reach backend", async () => {
    const before = calls;
    for (const headers of [{ host: "evil.example" }, { origin: "https://evil.example" }, { "sec-fetch-site": "cross-site" }, { origin: "null" }]) {
      assert.equal((await get(proxyUrl, { headers })).status, 403);
    }
    assert.equal(calls, before);
    assert.equal((await get(proxyUrl, { path: "/?token=browser-supplied" })).status, 400);
    assert.equal(calls, before);
  });
  await t.test("network-path normalization cannot send private cookies off-origin", async () => {
    const path = "/\\evil.example/private";
    assert.equal(new URL(path, upstream).hostname, "evil.example");
    const before = calls;
    assert.equal((await get(proxyUrl, { path })).status, 400);
    assert.equal(calls, before);
  });
  await t.test("credential redirects fail without leaking URL", async () => {
    const result = await get(proxyUrl, { path: "/bad-redirect" });
    assert.equal(result.status, 502);
    assert.equal(result.headers.location, undefined);
    assert.doesNotMatch(result.body, /fixture|token|cookie/);
  });
  await t.test("WebSocket upgrade relays frames without backend cookies", async () => {
    const result = await websocket(proxyUrl);
    assert.equal(result.status, 101);
    assert.equal(result.headers["set-cookie"], undefined);
    const expected = Buffer.from([0x81, 5, ...Buffer.from("ready"), 0x81, 4, ...Buffer.from("echo")]);
    await new Promise((resolve, reject) => {
      let received = result.head;
      const check = () => { if (received.length >= expected.length) { assert.deepEqual(received, expected); resolve(); } };
      result.socket.on("data", (chunk) => { received = Buffer.concat([received, chunk]); check(); });
      result.socket.on("error", reject);
      result.socket.write(maskedFrame("echo"));
      check();
    });
    result.socket.destroy();
  });
  await t.test("WebSocket401 race refreshes authentication before accepting", async () => {
    rotateUpgrade = true;
    const before = upgrades;
    const result = await websocket(proxyUrl);
    assert.equal(result.status, 101);
    assert.equal(upgrades, before + 2);
    result.socket.destroy();
  });
  await t.test("WebSocket admission applies identical browser and target fences", async () => {
    const before = upgrades;
    assert.equal((await websocket(proxyUrl, { headers: { origin: "https://evil.example" } })).status, 403);
    assert.equal((await websocket(proxyUrl, { path: "/\\evil.example" })).status, 400);
    assert.equal((await websocket(proxyUrl, { path: "/api/remote.mux?token=fixture" })).status, 400);
    assert.equal(upgrades, before);
  });
  await t.test("clean shutdown closes upgraded clients", async () => {
    const result = await websocket(proxyUrl);
    const closed = once(result.socket, "close");
    result.socket.resume();
    await stop(proxy);
    await closed;
  });
});
