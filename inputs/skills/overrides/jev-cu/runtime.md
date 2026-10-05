# Host-coordinated runtime

CUA reads and operates the UI. A separate host shell call performs each
BWS-backed Jev request. The BWS helper must never be imported into CUA, and
the current runtime cannot run an automatic BWS-backed `runTask` loop.

## Prepare a request in CUA

The first CUA invocation contains only this entry call. Read the returned
documentation before continuing:

```js
var jevApp = await cua.getApp("Calculator");
```

This later call is read-only. Use these APIs only if the current documentation
permits them. A Calculator example keeps the output to inspected button
candidates; exclude any history/result text or unrelated controls before
emitting the request. For another app, define a task-specific scope before
selecting candidates, and inspect every field that will leave the computer.

```js
var jevUrl = await import("node:url");
var jevRepo = "{{REPO_DIR}}";
var jevLoop = await import(jevUrl.pathToFileURL(jevRepo + "/scripts/loop.mjs").href);
var jevPolicy = await import(jevUrl.pathToFileURL(jevRepo + "/scripts/policy.mjs").href);
var jevGoal = "Choose the digit seven button in Calculator.";
var jevAxBefore = await jevApp.getAXState({ emit: false, disableDiffing: true });
var jevCandidates = jevLoop.selectCandidates(
  jevLoop.parseAX(jevAxBefore).filter(element => element.role === "button"),
  jevGoal,
  { max: 40 }
);
// Inspect these candidates locally and exclude unrelated/private labels first.
// Keep jevAxBefore and original complete labels in CUA memory.
var jevRequest = {
  goal: jevGoal,
  app: "Calculator",
  candidates: jevCandidates.map(({ index, role, label }) => ({ index, role, label })),
  context: "Only the inspected Calculator button candidates are included.",
  constraints: "Choose one candidate; do not execute anything."
};
nodeRepl.write(jevRequest);
```

Do not automatically forward this output until the candidates have been
reviewed and minimized. If the safe scope is unclear, narrow the task or use
Codex's direct operation instead. Unsupported imports/APIs are a boundary,
not a reason to import forbidden process modules or change official plugins.

## Call Jev on the host

The following is a synthetic, non-private **API fixture**, not a UI action.
Its indices must never be used against a real app. A live request uses only
the reviewed JSON from the current CUA observation. Supply JSON through stdin
using a quoted heredoc or a structured process pipe, never interpolated shell
text. No API key belongs in the request, command, or temporary files.

```sh
node '{{SELF_REPO}}/scripts/jev-cu-bws.mjs' --bws --repo '{{REPO_DIR}}' <<'JEV_REQUEST'
{"goal":"Choose the digit seven button.","app":"Calculator","candidates":[{"index":1,"role":"button","label":"7"},{"index":2,"role":"button","label":"8"}],"context":"Synthetic API fixture; no live GUI state.","constraints":"Return a decision only."}
JEV_REQUEST
```

If a temporary file is necessary for a live payload, create it with private
permissions, pass its path as stdin redirection, and remove it after the
request. It contains only the minimized payload, never credentials. The CLI
prints only decision JSON; do not print secret environment variables or
forward raw BWS output. `createBwsDecider` is available for ordinary host Node
programs, not for CUA imports.

## Reobserve and check policy in CUA

Bind `jevDecision` to the parsed JSON returned for this exact live request;
do not use the synthetic fixture result. The following call performs no
action. Full AX equality is deliberately conservative: if it fails, discard
the old decision and prepare another request from fresh state. A more focused
comparison must include every task-relevant state and target identity.

```js
var jevAxFresh = await jevApp.getAXState({ emit: false, disableDiffing: true });
if (jevAxFresh !== jevAxBefore) throw new Error("UI changed; discard the Jev decision.");
if (!jevCandidates.some(candidate => candidate.index === jevDecision.targetIndex)) {
  throw new Error("Decision does not select an offered live candidate.");
}
var jevTarget = jevLoop.parseAX(jevAxFresh).find(element => element.index === jevDecision.targetIndex);
if (!jevTarget) throw new Error("Target is absent from the fresh observation.");
var jevGate = jevPolicy.evaluatePolicy({
  decision: { ...jevDecision, targetLabel: jevTarget.label },
  app: "Calculator",
  step: 1,
  maxSteps: 1,
  dryRun: true
});
nodeRepl.write({ decision: jevDecision, target: jevTarget.label, gate: jevGate });
```

For `wait` or a claimed `done` without a target, do not invent one: wait/reobserve
or independently verify completion and finish without executing a target
action. A policy `done` is still only a claim. Invalid or uncertain decisions
require host assessment rather than lowering thresholds.

After a preview, execution requires an authorized action and fresh state
verification immediately before the action. Reevaluate the policy with the
full current label and `dryRun: false`. Inspect the returned action and any
text/key/scroll parameters, then issue exactly one matching documented CUA
operation. Do not paste a generic action dispatcher or let Jev invent input
text. Read the UI afterward and verify the expected effect and total goal.
Every additional step starts with a new observation and request.
