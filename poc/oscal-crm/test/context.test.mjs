import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdirSync, writeFileSync, readFileSync, symlinkSync } from "node:fs";
import { execFileSync } from "node:child_process";
import { fileURLToPath } from "node:url";
import { createHash, randomBytes } from "node:crypto";
import { loadContext } from "../context.mjs";
import { createApi } from "../server.mjs";
const cwd = fileURLToPath(new URL("../", import.meta.url));
execFileSync(process.execPath, ["export-demo.mjs"], { cwd });
const demo = new URL("../.cache/demo/", import.meta.url);
test("local OSCAL manifest round-trip and HTTP use loaded offering, not fixed fixtures", async (t) => {
  const context = loadContext(fileURLToPath(new URL("manifest.json", demo)));
  assert.equal(context.crm("enhanced").controls[0].effective_parameters[0].values[0], "7 days");
  assert.equal(
    context.document("ssp-enhanced")["system-security-plan"].metadata["oscal-version"],
    "1.1.3",
  );
  const token = randomBytes(32).toString("hex");
  const renamedRoot = new URL("../.cache/renamed-demo/", import.meta.url);
  mkdirSync(renamedRoot, { recursive: true });
  const renamed = JSON.parse(readFileSync(new URL("manifest.json", demo)));
  for (const entry of Object.values(renamed.documents))
    writeFileSync(new URL(entry.path, renamedRoot), readFileSync(new URL(entry.path, demo)));
  renamed.plans.forEach((p, i) => {
    p.offering = "local-hosting";
    p.plan = i ? "plus" : "basic";
  });
  renamed.instances[0].plan = "basic";
  writeFileSync(new URL("manifest.json", renamedRoot), JSON.stringify(renamed));
  const renamedContext = loadContext(fileURLToPath(new URL("manifest.json", renamedRoot)));
  assert.equal(renamedContext.catalog().services[0].id, "local-hosting");
  assert.equal(renamedContext.crm("managed"), null);
  assert.equal(renamedContext.crm("basic", "wrong-offering"), null);
  const copy = renamedContext.document("component");
  copy["component-definition"].metadata.title = "mutated";
  assert.notEqual(
    renamedContext.document("component")["component-definition"].metadata.title,
    "mutated",
  );
  const server = createApi({ token, context: renamedContext, audit: () => {} });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const result = await fetch(
    `http://127.0.0.1:${server.address().port}/api/crm/compare/basic/plus`,
    {
      headers: { authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(5000),
    },
  );
  assert.equal(result.status, 200);
  assert.equal((await result.json()).changes.length, 2);
  const loaded = await fetch(
    `http://127.0.0.1:${server.address().port}/api/crm/offerings/local-hosting/plans/basic`,
    {
      headers: { authorization: `Bearer ${token}` },
      signal: AbortSignal.timeout(5000),
    },
  );
  assert.equal(loaded.status, 200);
  assert.equal((await loaded.json()).offering_id, "local-hosting");
});
test("manifest rejects corruption, traversal, escape symlink, duplicates and non-synthetic input", () => {
  const root = new URL(`../.cache/test-${randomBytes(6).toString("hex")}/`, import.meta.url);
  mkdirSync(root, { recursive: true });
  const original = JSON.parse(readFileSync(new URL("manifest.json", demo)));
  for (const entry of Object.values(original.documents))
    writeFileSync(new URL(entry.path, root), readFileSync(new URL(entry.path, demo)));
  const attempt = (manifest) => {
    writeFileSync(new URL("manifest.json", root), JSON.stringify(manifest));
    return () => loadContext(fileURLToPath(new URL("manifest.json", root)));
  };
  const cases = [
    (m) => {
      m.synthetic = false;
    },
    (m) => {
      m.documents.component.sha256 = "0".repeat(64);
    },
    (m) => {
      m.documents.component.path = "../demo/component.json";
    },
    (m) => {
      m.plans.push(m.plans[0]);
    },
    (m) => {
      m.plans[0].documentName = "missing";
    },
    (m) => {
      m.instances[0].tenant = "other";
    },
  ];
  for (const mutate of cases) {
    const value = structuredClone(original);
    mutate(value);
    assert.throws(attempt(value));
  }
  symlinkSync(fileURLToPath(new URL("component.json", demo)), new URL("escape.json", root));
  const escape = structuredClone(original);
  escape.documents.component.path = "escape.json";
  assert.throws(attempt(escape), /escapes/);
  writeFileSync(new URL("large.json", root), " ".repeat(2 * 1024 * 1024 + 1));
  const large = structuredClone(original);
  large.documents.component.path = "large.json";
  assert.throws(attempt(large), /size limit/);
  const raw = JSON.stringify({ constructor: "invalid" });
  writeFileSync(new URL("reserved.json", root), raw);
  const reserved = structuredClone(original);
  reserved.documents.component = {
    path: "reserved.json",
    sha256: createHash("sha256").update(raw).digest("hex"),
  };
  assert.throws(attempt(reserved), /Reserved/);
});
