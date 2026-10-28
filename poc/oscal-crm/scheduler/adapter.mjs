// Test-only adapter: empty scheduler POST -> configured, read-only CRM GETs.
import { createServer } from "node:http";
import { timingSafeEqual } from "node:crypto";
import { loopbackUrl } from "./contract-mock.mjs";
import { validateCrm } from "../contract.mjs";
import { digest } from "../model.mjs";

function token(value) {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{32,128}$/.test(value))
    throw new Error("Invalid test adapter token");
  return value;
}
function authorized(header, expected) {
  const actual = Buffer.from(header || ""),
    wanted = Buffer.from(`Bearer ${expected}`);
  return actual.length === wanted.length && timingSafeEqual(actual, wanted);
}
async function readJson(response, maximum = 2 * 1024 * 1024) {
  if (!response.ok || !response.headers.get("content-type")?.includes("application/json")) {
    await response.body?.cancel();
    throw new Error("Upstream response rejected");
  }
  const reader = response.body.getReader();
  let size = 0;
  const chunks = [];
  try {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > maximum) throw new Error("Upstream response exceeds bound");
      chunks.push(Buffer.from(value));
    }
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } finally {
    await reader.cancel();
  }
}
export function createTriggerAdapter({
  crmBase,
  triggerToken,
  crmToken,
  offering = "managed-hosting",
  plan = "managed",
  instance = null,
  tenant = "demo-tenant",
  timeoutMs = 500,
  audit = console.log,
} = {}) {
  const base = loopbackUrl(crmBase);
  if (base.pathname !== "/") throw new Error("CRM base must have root path");
  token(triggerToken);
  token(crmToken);
  if (triggerToken === crmToken) throw new Error("Use separate adapter and CRM tokens");
  for (const id of [offering, plan, ...(instance ? [instance] : [])]) {
    if (!/^[a-z][a-z0-9-]{0,63}$/.test(id))
      throw new Error("Invalid configured context identifier");
  }
  if (tenant !== "demo-tenant") throw new Error("Only synthetic tenant is allowed");
  if (!Number.isInteger(timeoutMs) || timeoutMs < 1 || timeoutMs > 5000)
    throw new Error("Invalid adapter timeout");
  return createServer(async (req, res) => {
    const send = (status, body) => {
      audit(
        JSON.stringify({
          timestamp: new Date().toISOString(),
          event: "mock_scheduler_trigger",
          status,
          synthetic: true,
        }),
      );
      res.writeHead(status, { "content-type": "application/json", "cache-control": "no-store" });
      res.end(JSON.stringify(body));
    };
    if (!authorized(req.headers.authorization, triggerToken))
      return send(401, { code: "UNAUTHORIZED" });
    if (req.url !== "/trigger") return send(404, { code: "NOT_FOUND" });
    if (req.method !== "POST") return send(405, { code: "METHOD_NOT_ALLOWED" });
    let bodySize = 0;
    try {
      for await (const chunk of req) {
        bodySize += chunk.length;
        if (bodySize > 1024) {
          send(413, { code: "PAYLOAD_TOO_LARGE" });
          return;
        }
      }
      if (bodySize) return send(400, { code: "EMPTY_BODY_REQUIRED" });
      const signal = AbortSignal.timeout(timeoutMs);
      const headers = { authorization: `Bearer ${crmToken}`, "x-crm-tenant": tenant };
      const get = async (path) =>
        readJson(
          await fetch(new URL(path, base), {
            headers,
            signal,
            redirect: "manual",
          }),
        );
      const catalog = await get("/v2/catalog");
      const service = catalog.services?.find((s) => s.id === offering);
      if (!service?.plans?.some((p) => p.id === plan))
        throw new Error("Configured offering/plan is not discoverable");
      const crm = await get(
        instance
          ? `/api/crm/instances/${instance}`
          : `/api/crm/offerings/${offering}/plans/${plan}`,
      );
      const { instance_id, tenant_id, parameter_basis, ...projection } = crm;
      validateCrm(projection);
      if (
        projection.offering_id !== offering ||
        projection.plan_id !== plan ||
        (instance && (instance_id !== instance || tenant_id !== tenant))
      )
        throw new Error("Context mismatch");
      if (projection.source_documents.length !== 2)
        throw new Error("Expected two source documents");
      for (const source of projection.source_documents) {
        if (!/^\/api\/oscal\/[a-z][a-z0-9-]{0,63}$/.test(source.uri))
          throw new Error("Source URI not allowed");
        const document = await get(source.uri);
        if (digest(document) !== source.sha256) throw new Error("Document integrity mismatch");
      }
      send(200, {
        synthetic: true,
        result: "context-retrieved",
        assessed: false,
        projection_sha256: digest(projection),
        controls: projection.controls.map((row) => ({
          control_id: row.control_id,
          component_uuid: row.component_uuid,
          declared_state: row.implemented.declared_state,
          customer_responsibilities: row.required.responsibilities,
          effective_parameters: row.effective_parameters,
          evidence: row.implemented.evidence,
        })),
      });
    } catch {
      send(502, { synthetic: true, code: "CRM_RETRIEVAL_FAILED", assessed: false });
    }
  });
}
