import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import { createApi } from "../server.mjs";
import { buildCrm, documents, digest, crmForPlan, comparePlans } from "../model.mjs";
import { validateDocuments } from "../validate.mjs";
import { registry, uuid } from "../fixtures/documents.mjs";
import { validateCrm } from "../contract.mjs";

test("official OSCAL schemas and native references validate", () => {
  assert.equal(validateDocuments(), true);
  const broken = structuredClone(documents);
  broken.component["component-definition"].uuid = "invalid";
  assert.throws(() => validateDocuments(broken), /schema/);
});
test("CRM preserves declared states, responsibilities, parameters and unknowns", () => {
  const crm = buildCrm();
  assert.deepEqual(
    crm.controls.map((c) => c.implemented.declared_state),
    ["implemented", "partial", "unknown"],
  );
  for (const row of crm.controls) {
    assert.equal(row.implemented.evidence.state, "not-assessed");
    assert.equal(row.required.state, "confirmed-by-source");
    assert.equal(row.inheritance.state, "pending-provider-evidence");
    assert.deepEqual(row.required.satisfaction, []);
  }
  assert.equal(crm.controls[0].effective_parameters[0].values[0], "30 days");
  assert.equal(crm.source_documents[0].sha256, digest(documents.component));
});
test("malformed mappings, dangling references and duplicate UUIDs fail closed", () => {
  assert.throws(
    () => buildCrm(undefined, undefined, { ...registry, capability: uuid(999) }),
    /mapping/,
  );
  const broken = structuredClone(documents);
  const by =
    broken.ssp["system-security-plan"]["control-implementation"]["implemented-requirements"][0]
      .statements[0]["by-components"][0];
  by.export.responsibilities[0]["provided-uuid"] = uuid(999);
  assert.throws(() => validateDocuments(broken), /Dangling/);
  by.export.responsibilities[0]["provided-uuid"] = by.export.provided[0].uuid;
  by.export.responsibilities[0].uuid = by.uuid;
  assert.throws(() => validateDocuments(broken), /Duplicate/);
});
test("missing customer facts remain unknown, not none-required", () => {
  const ssp = structuredClone(documents.ssp);
  delete ssp["system-security-plan"]["control-implementation"]["implemented-requirements"][0]
    .statements[0]["by-components"][0].export;
  assert.equal(buildCrm(documents.component, ssp).controls[0].required.state, "unknown");
});
test("bad server configuration is rejected", () => {
  assert.throws(() => createApi({ token: "short" }), /TOKEN/);
  assert.throws(() => createApi({ token: "a".repeat(32), tenant: "other" }), /tenant/);
});
test("two plans compose multiple components and report scope/parameter/residual differences", () => {
  assert.equal(new Set(crmForPlan("managed").controls.map((r) => r.component_uuid)).size, 3);
  assert.equal(crmForPlan("enhanced").controls[1].implemented.declared_state, "implemented");
  assert.deepEqual(
    comparePlans("managed", "enhanced").changes.map((c) => c.before.control_id),
    ["ac-2", "au-2"],
  );
  assert.deepEqual(comparePlans("managed", "managed").changes, []);
  assert.equal(crmForPlan("constructor"), null);
  assert.equal(comparePlans("unknown", "managed"), null);
});
test("unresolved roles/components and mismatched statements are rejected", () => {
  for (const kind of ["role", "component", "statement"]) {
    const input = structuredClone(documents);
    const statement =
      input.ssp["system-security-plan"]["control-implementation"]["implemented-requirements"][0]
        .statements[0];
    if (kind === "role")
      statement["by-components"][0].export.provided[0]["responsible-roles"][0]["role-id"] =
        "missing";
    if (kind === "component") statement["by-components"][0]["component-uuid"] = uuid(999);
    if (kind === "statement") statement["statement-id"] = "ac-2_smt.missing";
    assert.throws(() => validateDocuments(input), /Dangling|statement/);
  }
});
test("strict CRM response schema rejects unknown fields and malformed states", () => {
  const crm = buildCrm();
  crm.unexpected = true;
  assert.throws(() => validateCrm(crm), /projection schema/);
  delete crm.unexpected;
  crm.controls[0].implemented.claim_basis = "compliant";
  assert.throws(() => validateCrm(crm), /projection schema/);
});
test("live HTTP discovery, CRM, documents, notes and deny paths", async (t) => {
  const token = randomBytes(32).toString("hex");
  const logs = [];
  const server = createApi({ token, audit: (line) => logs.push(line) });
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  t.after(() => new Promise((resolve) => server.close(resolve)));
  const base = `http://127.0.0.1:${server.address().port}`;
  const request = (path, options = {}) =>
    fetch(base + path, {
      ...options,
      headers: { authorization: `Bearer ${token}`, ...options.headers },
      signal: AbortSignal.timeout(5000),
    });
  assert.equal((await fetch(base + "/health")).status, 401);
  const viewer = await fetch(base + "/");
  assert.equal(viewer.status, 200);
  assert.match(viewer.headers.get("content-security-policy"), /script-src 'self'/);
  assert.match(await viewer.text(), /id="rows"/);
  const script = await fetch(base + "/viewer.mjs");
  assert.equal(script.status, 200);
  assert.match(await script.text(), /textContent/);
  assert.equal((await fetch(base + "/viewer.css")).status, 200);
  for (const path of [
    "/health",
    "/v2/catalog",
    "/api/openapi.json",
    "/api/notes/component-model",
    `/api/components/${uuid(2)}`,
    "/api/oscal/component",
    "/api/oscal/ssp",
    "/api/crm/offerings/managed-hosting/plans/managed",
    "/api/crm/offerings/managed-hosting/plans/enhanced",
    "/api/crm/compare/managed/enhanced",
    "/api/oscal/ssp-enhanced",
  ]) {
    const response = await request(path);
    assert.equal(response.status, 200, path);
    assert.equal(response.headers.get("cache-control"), "no-store");
    assert.ok(await response.json());
  }
  assert.equal((await request("/api/crm/instances/demo-instance")).status, 404);
  assert.equal(
    (await request("/api/crm/instances/demo-instance", { headers: { "x-crm-tenant": "other" } }))
      .status,
    404,
  );
  const instance = await request("/api/crm/instances/demo-instance", {
    headers: { "x-crm-tenant": "demo-tenant" },
  });
  assert.equal(instance.status, 200);
  assert.equal((await instance.json()).controls.length, 3);
  assert.equal((await request("/api/crm/offerings/unknown/plans/managed")).status, 404);
  assert.equal((await request("/health?token=secret")).status, 400);
  assert.equal((await request("/v2/catalog", { method: "POST" })).status, 405);
  assert.equal(
    logs.some((line) => line.includes(token) || line.includes("secret")),
    false,
  );
});
