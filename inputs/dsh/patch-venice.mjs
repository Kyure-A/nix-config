import assert from 'node:assert/strict';
import { readFileSync, writeFileSync } from 'node:fs';

const [target, helperPath] = process.argv.slice(2);
const source = readFileSync(target, 'utf8');
const anchor = 'headers: requestHeaders(profile.headers)';
assert.equal(source.split(anchor).length, 2, 'DSH adapter changed; review the Venice compatibility patch');
const helper = readFileSync(helperPath, 'utf8').replace('export function', 'function');
writeFileSync(target, helper + '\n' + source.replace(anchor,
  anchor + ',\n onPayload: payload => venicePayload(profile, model, payload)'));
