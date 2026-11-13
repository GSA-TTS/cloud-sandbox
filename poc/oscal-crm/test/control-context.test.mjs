import { test } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { randomBytes } from "node:crypto";
import { fileURLToPath } from "node:url";
import { execFileSync } from "node:child_process";
import { createContext, loadContext } from "../context.mjs";
import { createApi } from "../server.mjs";
import { planFixtures } from "../fixtures/documents.mjs";
import { crmForPlan, digest } from "../model.mjs";

const cwd = fileURLToPath(new URL("../", import.meta.url));
execFileSync(process.execPath, ["export-demo.mjs"], { cwd });
const demo = fileURLToPath(new URL("../.cache/demo/manifest.json", import.meta.url));
const mapping = JSON.parse(
  readFileSync(new URL("../mappings/offering-plan.json", import.meta.url), "utf8"),
);

test("native mapping file round-trips to the source registry and exported manifest", () => {
  const exported = JSON.parse(readFileSync(demo, "utf8"));
  assert.equal(mapping.version, 1);
  assert.equal(mapping.synthetic, true);
  assert.equal(mapping.offerings.length, Object.keys(planFixtures).length);
  for (const entry of mapping.offerings) {
    const source = planFixtures[entry.plan].mapping;
    assert.equal(entry.offering, source.offering);
    assert.equal(entry.capability, source.capability);
    assert.equal(entry.controlImplementation, source.controlImplementation);
    assert.equal(entry.component, source.component);
    assert.deepEqual(entry.components, source.components);
    assert.deepEqual(entry.claimBasis, source.claimBasis);
    assert.ok(exported.plans.some((p) => p.plan === entry.plan && p.offering === entry.offering));
  }
});

test("CRM output is deterministic and identical after export and reload", () => {
  const inMemory = crmForPlan("managed");
  const reloaded = loadContext(demo).crm("managed");
  assert.equal(digest(reloaded), digest(inMemory));
  assert.equal(digest(crmForPlan("managed")), digest(inMemory));
});

test("binding context is digest-bound and carries explicit parameter snapshot", () => {
  const context = createContext();
  const binding = context.binding("managed-hosting", "managed", "demo-instance", "demo-tenant");
  assert.equal(binding.profile, "urn:cloud-sandbox:poc:crm:1");
  assert.equal(binding.profile_version, "0.1.0");
  assert.equal(binding.parameter_snapshot.state, "explicit-source");
  const { context_digest, ...body } = binding;
  assert.equal(digest(body), context_digest);
  assert.equal(context.binding("other", "managed", "demo-instance", "demo-tenant"), null);
  assert.equal(
    context.binding("managed-hosting", "enhanced", "demo-instance", "demo-tenant"),
    null,
  );
  assert.equal(context.binding("managed-hosting", "managed", "missing", "demo-tenant"), null);
  assert.equal(context.binding("managed-hosting", "managed", "demo-instance", "other"), null);
});

test("HTTP binding endpoint enforces auth, tenant, digest and legacy catalog shape", async (t) => {
  const token = randomBytes(32).toString("hex");
  const server = createApi({ token, audit: () => {} });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const get = (path, headers = {}) =>
    fetch(base + path, {
      headers: { authorization: `Bearer ${token}`, ...headers },
      signal: AbortSignal.timeout(5000),
    });
  const bindingPath = "/api/crm/context/managed-hosting/managed/demo-instance";

  assert.equal((await fetch(base + bindingPath)).status, 401);
  assert.equal((await get(bindingPath)).status, 404);
  assert.equal((await get(bindingPath, { "x-crm-tenant": "other" })).status, 404);

  const ok = await get(bindingPath, { "x-crm-tenant": "demo-tenant" });
  assert.equal(ok.status, 200);
  const body = await ok.json();
  assert.equal(body.offering_id, "managed-hosting");

  const mismatch = await get(bindingPath, {
    "x-crm-tenant": "demo-tenant",
    "if-match": '"' + "0".repeat(64) + '"',
  });
  assert.equal(mismatch.status, 409);
  assert.equal((await mismatch.json()).error.code, "CONTEXT_DIGEST_MISMATCH");

  const matched = await get(bindingPath, {
    "x-crm-tenant": "demo-tenant",
    "if-match": `"${body.context_digest}"`,
  });
  assert.equal(matched.status, 200);

  const catalog = await (await get("/v2/catalog")).json();
  const service = catalog.services[0];
  assert.equal(service.bindable, false);
  assert.equal(service.metadata.oscal_crm.profile, "urn:cloud-sandbox:poc:crm:1");
  assert.equal(service.metadata.oscal_crm.version, "0.1.0");
  assert.ok(service.plans[0].metadata.crm_documents.every((d) => /^[0-9a-f]{64}$/.test(d.sha256)));
});
