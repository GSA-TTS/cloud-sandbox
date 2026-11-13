import Ajv from "ajv";

const text = { type: "string", minLength: 1 };
const strings = { type: "array", items: text, uniqueItems: true };
const uuid = {
  type: "string",
  pattern: "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
};
const object = (properties) => ({
  type: "object",
  additionalProperties: false,
  required: Object.keys(properties),
  properties,
});
const array = (items) => ({ type: "array", items });
const native = (properties) => ({
  type: "object",
  additionalProperties: false,
  required: ["uuid", "description"],
  properties: { uuid, description: text, ...properties },
});
const role = array(object({ "role-id": text }));
const provided = native({ "responsible-roles": role });
const responsibility = native({ "provided-uuid": uuid, "responsible-roles": role });
const inherited = native({ "provided-uuid": uuid, "responsible-roles": role });
const satisfied = native({ "responsibility-uuid": uuid, "responsible-roles": role });
export const crmSchema = object({
  profile: { const: "urn:cloud-sandbox:poc:crm:1" },
  version: { const: "0.1.0" },
  synthetic: { const: true },
  offering_id: text,
  plan_id: text,
  capability_uuid: uuid,
  component_uuid: uuid,
  source_documents: array(
    object({
      uri: text,
      sha256: { type: "string", pattern: "^[0-9a-f]{64}$" },
      oscal_version: { const: "1.1.3" },
      synthetic: { const: true },
    }),
  ),
  interpretation: text,
  controls: {
    ...array(
      object({
        control_id: { type: "string", pattern: "^[a-z]{2}-[0-9]+(?:\\.[0-9]+)?$" },
        statement_id: text,
        component_uuid: uuid,
        by_component_uuid: uuid,
        implemented: object({
          declared_state: text,
          narrative: text,
          provided: array(provided),
          responsible_roles: strings,
          claim_basis: { enum: ["provider-default", "explicit-plan-configuration", "unknown"] },
          evidence: object({
            state: { const: "not-assessed" },
            observations: { type: "array", maxItems: 0 },
          }),
        }),
        required: object({
          state: { enum: ["confirmed-by-source", "unknown"] },
          responsibilities: array(responsibility),
          responsible_roles: strings,
          satisfaction: array(satisfied),
        }),
        inheritance: object({
          state: { enum: ["source-declared", "pending-provider-evidence"] },
          accepted_claims: array(inherited),
        }),
        effective_parameters: array(object({ "param-id": text, values: strings })),
        source_refs: object({
          declaration_uuid: uuid,
          statement_uuid: uuid,
          by_component_uuid: uuid,
        }),
      }),
    ),
    minItems: 1,
  },
});
const validate = new Ajv({ strict: true, allErrors: true }).compile(crmSchema);
export function validateCrm(value) {
  if (!validate(value))
    throw new Error(`CRM projection schema: ${JSON.stringify(validate.errors)}`);
  return value;
}
