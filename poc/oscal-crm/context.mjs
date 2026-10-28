import Ajv from "ajv";
import { readFileSync, realpathSync, statSync } from "node:fs";
import { dirname, relative, resolve, isAbsolute } from "node:path";
import { fileURLToPath } from "node:url";
import { createHash } from "node:crypto";
import { documents, catalog, crmForPlan, componentDetails, comparePlans } from "./model.mjs";
import { planFixtures, registry } from "./fixtures/documents.mjs";
import { validateDocuments } from "./validate.mjs";

const id = { type: "string", pattern: "^[a-z][a-z0-9-]{0,63}$" };
const uuid = {
  type: "string",
  pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
};
const strict = (properties) => ({
  type: "object",
  additionalProperties: false,
  required: Object.keys(properties),
  properties,
});
const file = strict({
  path: { type: "string", minLength: 1, maxLength: 256 },
  sha256: { type: "string", pattern: "^[0-9a-f]{64}$" },
});
export const manifestSchema = strict({
  version: { const: 1 },
  synthetic: { const: true },
  documents: {
    type: "object",
    minProperties: 2,
    maxProperties: 17,
    propertyNames: id,
    additionalProperties: file,
  },
  plans: {
    type: "array",
    minItems: 1,
    maxItems: 16,
    items: strict({
      offering: id,
      plan: id,
      capability: uuid,
      controlImplementation: uuid,
      component: uuid,
      components: { type: "array", minItems: 1, maxItems: 32, uniqueItems: true, items: uuid },
      documentName: id,
      claimBasis: {
        type: "object",
        maxProperties: 1000,
        propertyNames: { pattern: "^[a-z]{2}-[0-9]+(?:\\.[0-9]+)?$" },
        additionalProperties: {
          enum: ["provider-default", "explicit-plan-configuration", "unknown"],
        },
      },
    }),
  },
  instances: {
    type: "array",
    maxItems: 100,
    items: strict({ id, tenant: { const: "demo-tenant" }, plan: id }),
  },
});
const validateManifest = new Ajv({ strict: true, allErrors: true }).compile(manifestSchema);
const limit = 2 * 1024 * 1024;
function boundedJson(path, maximum = limit) {
  const stats = statSync(path);
  if (!stats.isFile() || stats.size > maximum)
    throw new Error("Context file exceeds size limit or is not a file");
  const bytes = readFileSync(path);
  if (bytes.length > maximum) throw new Error("Context file exceeds size limit");
  const value = JSON.parse(bytes.toString("utf8"));
  const visit = (node, depth = 0) => {
    if (depth > 64) throw new Error("Context nesting exceeds limit");
    if (node && typeof node === "object") {
      for (const [key, child] of Object.entries(node)) {
        if (["__proto__", "constructor", "prototype"].includes(key))
          throw new Error("Reserved context key");
        visit(child, depth + 1);
      }
    }
  };
  visit(value);
  return { value, bytes };
}
function containedPath(root, path) {
  if (
    isAbsolute(path) ||
    path.includes("\\") ||
    path.split("/").some((p) => ["..", ".", ""].includes(p))
  ) {
    throw new Error("Document path must be a contained relative path");
  }
  const resolved = realpathSync(resolve(root, path));
  const rel = relative(root, resolved);
  if (rel.startsWith("..") || isAbsolute(rel))
    throw new Error("Document path escapes manifest directory");
  return resolved;
}
export function loadContext(manifestPath) {
  // Explicit operator-selected local file only; never use request input as a path.
  const path = realpathSync(manifestPath);
  const root = dirname(path);
  const { value: manifest } = boundedJson(path, 64 * 1024);
  if (!validateManifest(manifest)) throw new Error("Invalid synthetic context manifest");
  if (!Object.hasOwn(manifest.documents, "component"))
    throw new Error("Missing component document");
  const input = Object.create(null);
  for (const [name, entry] of Object.entries(manifest.documents)) {
    const { value, bytes } = boundedJson(containedPath(root, entry.path));
    if (createHash("sha256").update(bytes).digest("hex") !== entry.sha256)
      throw new Error("Context file digest mismatch");
    input[name] = value;
  }
  const plans = Object.create(null);
  for (const mapping of manifest.plans) {
    if (Object.hasOwn(plans, mapping.plan)) throw new Error("Duplicate plan identifier");
    if (mapping.documentName === "component" || !Object.hasOwn(input, mapping.documentName))
      throw new Error("Missing consumer document");
    if (!mapping.components.includes(mapping.component))
      throw new Error("Plan anchor is not in component list");
    plans[mapping.plan] = { mapping, ssp: input[mapping.documentName] };
  }
  const ids = new Set();
  for (const instance of manifest.instances) {
    if (ids.has(instance.id) || !Object.hasOwn(plans, instance.plan))
      throw new Error("Duplicate or unmapped instance");
    ids.add(instance.id);
  }
  validateDocuments(input, manifest.plans);
  return createContext(input, plans, manifest.instances);
}
export function createContext(
  input = documents,
  plans = planFixtures,
  instances = registry.instances.map((i) => ({ ...i, plan: registry.plan })),
) {
  const snapshot = structuredClone({ input, plans, instances });
  validateDocuments(
    snapshot.input,
    Object.values(snapshot.plans).map((f) => f.mapping),
  );
  return {
    catalog: () => catalog(snapshot.plans),
    crm: (plan, offering) => {
      const result = crmForPlan(plan, snapshot.input.component, snapshot.plans);
      return result && (!offering || result.offering_id === offering) ? result : null;
    },
    component: (id) => componentDetails(id, snapshot.input.component, snapshot.plans),
    compare: (from, to) => comparePlans(from, to, snapshot.input.component, snapshot.plans),
    document: (name) =>
      Object.hasOwn(snapshot.input, name) ? structuredClone(snapshot.input[name]) : null,
    instance: (id, tenant) => {
      const instance = snapshot.instances.find((i) => i.id === id && i.tenant === tenant);
      if (!instance) return null;
      return {
        ...crmForPlan(instance.plan, snapshot.input.component, snapshot.plans),
        instance_id: instance.id,
        tenant_id: instance.tenant,
        parameter_basis: "synthetic source snapshot; not a live broker observation",
      };
    },
  };
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  if (!process.argv[2]) throw new Error("Provide a local manifest path");
  const context = loadContext(process.argv[2]);
  console.log(
    JSON.stringify({ result: "PASS", synthetic: true, catalog: context.catalog() }, null, 2),
  );
}
