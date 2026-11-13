import { randomBytes } from "node:crypto";
import { writeFileSync } from "node:fs";
import assert from "node:assert/strict";
import { createApi } from "./server.mjs";
import { validateDocuments } from "./validate.mjs";
import { loadContext } from "./context.mjs";
import { fileURLToPath } from "node:url";

validateDocuments();
const token = randomBytes(32).toString("hex");
const context = loadContext(fileURLToPath(new URL("./.cache/demo/manifest.json", import.meta.url)));
const server = createApi({ token, context });
await new Promise((resolve, reject) => {
  server.once("error", reject);
  server.listen(0, "127.0.0.1", resolve);
});
const base = `http://127.0.0.1:${server.address().port}`;
const proof = {
  timestamp: new Date().toISOString(),
  mode: "live loopback HTTP",
  synthetic: true,
  steps: [],
};
async function observe(path, expected, headers = { authorization: `Bearer ${token}` }) {
  const response = await fetch(base + path, { headers, signal: AbortSignal.timeout(5000) });
  const body = await response.json();
  proof.steps.push({ path, status: response.status, body });
  assert.equal(response.status, expected);
  return body;
}
try {
  const catalog = await observe("/v2/catalog", 200);
  const crm = await observe(catalog.services[0].metadata.oscal_crm.href, 200);
  await observe("/api/crm/offerings/managed-hosting/plans/enhanced", 200);
  const comparison = await observe("/api/crm/compare/managed/enhanced", 200);
  assert.equal(comparison.changes.length, 2);
  const viewer = await fetch(base + "/", { signal: AbortSignal.timeout(5000) });
  assert.equal(viewer.status, 200);
  proof.steps.push({
    path: "/",
    status: viewer.status,
    body: { viewer_html_served: (await viewer.text()).includes('id="rows"') },
  });
  assert.deepEqual(
    crm.controls.map((c) => c.implemented.declared_state),
    ["implemented", "partial", "unknown"],
  );
  await observe(`/api/components/${crm.component_uuid}`, 200);
  await observe("/api/oscal/component", 200);
  await observe("/api/oscal/ssp", 200);
  await observe("/api/crm/instances/demo-instance", 200, {
    authorization: `Bearer ${token}`,
    "x-crm-tenant": "demo-tenant",
  });
  await observe("/api/crm/instances/demo-instance", 404, {
    authorization: `Bearer ${token}`,
    "x-crm-tenant": "other",
  });
  await observe("/health", 401, {});
  await observe("/health?unexpected=true", 400);
  proof.result = "PASS";
  writeFileSync(new URL("./proof.json", import.meta.url), JSON.stringify(proof, null, 2));
  console.log(
    JSON.stringify(
      {
        result: proof.result,
        mode: proof.mode,
        steps: proof.steps.map(({ path, status }) => ({ path, status })),
        crm: crm.controls.map((c) => ({
          control: c.control_id,
          implemented: c.implemented.declared_state,
          customer_required: c.required.responsibilities.map((r) => r.description),
          evidence: c.implemented.evidence.state,
        })),
        artifact: "poc/oscal-crm/proof.json",
      },
      null,
      2,
    ),
  );
} finally {
  await new Promise((resolve) => server.close(resolve));
}
