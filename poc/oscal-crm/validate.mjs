import Ajv from "ajv";
import addFormats from "ajv-formats";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { documents, buildCrm } from "./model.mjs";
import { enhancedRegistry } from "./fixtures/documents.mjs";

export function validateDocuments(input = documents, mappings = null) {
  const ajv = new Ajv({ strict: false, allErrors: true });
  addFormats(ajv);
  // OSCAL's vendored schemas also constrain these datatypes with patterns.
  ajv.addFormat("uri-reference", /^[^\s]*$/);
  const validators = new Map();
  for (const name of Object.keys(input)) {
    const path = new URL(
      `./.cache/${name === "component" ? "component" : "ssp"}.json`,
      import.meta.url,
    );
    const key = path.href;
    if (!validators.has(key))
      validators.set(key, ajv.compile(JSON.parse(readFileSync(path, "utf8"))));
    const validate = validators.get(key);
    if (!validate(input[name])) {
      throw new Error(`${name} OSCAL schema: ${JSON.stringify(validate.errors)}`);
    }
  }
  validateReferences(input, mappings);
  return true;
}
function validateReferences(input, mappings) {
  for (const document of Object.values(input)) {
    const ids = new Set();
    const root = Object.values(document)[0];
    const roleIds = new Set((root.metadata.roles || []).map((r) => r.id));
    const componentIds = new Set(
      (root.components || root["system-implementation"]?.components || []).map((c) => c.uuid),
    );
    const visit = (value) => {
      if (!value || typeof value !== "object") return;
      if (value.uuid) {
        if (ids.has(value.uuid)) throw new Error("Duplicate UUID in OSCAL document");
        ids.add(value.uuid);
      }
      if (value["role-id"] && !roleIds.has(value["role-id"]))
        throw new Error("Dangling role reference");
      for (const id of value["role-ids"] || [])
        if (!roleIds.has(id)) throw new Error("Dangling role reference");
      if (value["component-uuid"] && !componentIds.has(value["component-uuid"]))
        throw new Error("Dangling component reference");
      for (const child of Object.values(value)) visit(child);
    };
    visit(document);
  }
  const definition = input.component["component-definition"];
  const componentIds = new Set(definition.components.map((c) => c.uuid));
  for (const capability of definition.capabilities) {
    for (const incorporated of capability["incorporates-components"]) {
      if (!componentIds.has(incorporated["component-uuid"]))
        throw new Error("Dangling component reference");
    }
  }
  if (mappings) {
    for (const mapping of mappings) buildCrm(input.component, input[mapping.documentName], mapping);
  } else {
    buildCrm(input.component, input.ssp);
    if (input["ssp-enhanced"]) buildCrm(input.component, input["ssp-enhanced"], enhancedRegistry);
  }
}
if (process.argv[1] === fileURLToPath(import.meta.url)) {
  validateDocuments();
  console.log(
    "PASS: component-definition + SSP official schemas, UUID uniqueness and CRM references.",
  );
}
