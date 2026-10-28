import { createHash } from "node:crypto";
import {
  componentDocument,
  sspDocument,
  registry,
  enhancedSspDocument,
  planFixtures,
} from "./fixtures/documents.mjs";
import { validateCrm } from "./contract.mjs";

export const documents = {
  component: componentDocument,
  ssp: sspDocument,
  "ssp-enhanced": enhancedSspDocument,
};
export const digest = (value) => createHash("sha256").update(JSON.stringify(value)).digest("hex");
const source = (name, document = documents[name]) => ({
  uri: `/api/oscal/${name}`,
  sha256: digest(document),
  oscal_version: "1.1.3",
  synthetic: true,
});
const roles = (entries) =>
  entries.flatMap((e) => (e["responsible-roles"] || []).map((r) => r["role-id"]));
export function buildCrm(component = componentDocument, ssp = sspDocument, mapping = registry) {
  const capability = component["component-definition"].capabilities.find(
    (c) => c.uuid === mapping.capability,
  );
  const implementation = capability?.["control-implementations"].find(
    (c) => c.uuid === mapping.controlImplementation,
  );
  if (!implementation) throw new Error("Offering/plan mapping does not resolve");
  const incorporated = new Set(
    capability["incorporates-components"].map((c) => c["component-uuid"]),
  );
  const componentIds = mapping.components || [mapping.component];
  if (componentIds.some((id) => !incorporated.has(id)))
    throw new Error("Plan component is not incorporated");
  const requirements =
    ssp["system-security-plan"]["control-implementation"]["implemented-requirements"];
  const rows = implementation["implemented-requirements"].flatMap((declaration) => {
    const requirement = requirements.find((r) => r["control-id"] === declaration["control-id"]);
    if (!requirement) throw new Error("Declared control has no consumer CRM context");
    const declaredStatements = new Set(
      (declaration.statements || []).map((s) => s["statement-id"]),
    );
    if ((requirement.statements || []).some((s) => !declaredStatements.has(s["statement-id"]))) {
      throw new Error("Consumer statement does not match declared statement");
    }
    const projected = (requirement.statements || []).flatMap((statement) =>
      (statement["by-components"] || [])
        .filter((b) => componentIds.includes(b["component-uuid"]))
        .map((by) => projectRow(declaration, statement, by, mapping)),
    );
    if (!projected.length) throw new Error("Declared control has no mapped component context");
    return projected;
  });
  if (!rows.length) throw new Error("No CRM rows resolve");
  return validateCrm({
    profile: "urn:cloud-sandbox:poc:crm:1",
    version: "0.1.0",
    synthetic: true,
    offering_id: mapping.offering,
    plan_id: mapping.plan,
    capability_uuid: mapping.capability,
    component_uuid: mapping.component,
    source_documents: [source("component", component), source(mapping.documentName || "ssp", ssp)],
    interpretation:
      "Source declarations only. No independent assessment or authorization is asserted.",
    controls: rows,
  });
}
function projectRow(declaration, statement, by, mapping) {
  const provided = by.export?.provided || [];
  const required = by.export?.responsibilities || [];
  const providedIds = new Set(provided.map((p) => p.uuid));
  const responsibilityIds = new Set(required.map((r) => r.uuid));
  for (const r of required) {
    if (r["provided-uuid"] && !providedIds.has(r["provided-uuid"]))
      throw new Error("Dangling provided reference");
  }
  for (const inherited of by.inherited || []) {
    if (!providedIds.has(inherited["provided-uuid"]))
      throw new Error("Dangling inheritance reference");
  }
  for (const satisfied of by.satisfied || []) {
    if (!responsibilityIds.has(satisfied["responsibility-uuid"]))
      throw new Error("Dangling satisfaction reference");
  }
  return {
    control_id: declaration["control-id"],
    statement_id: statement["statement-id"],
    component_uuid: by["component-uuid"],
    by_component_uuid: by.uuid,
    implemented: {
      declared_state: by["implementation-status"]?.state || "unknown",
      narrative: by.description,
      provided,
      responsible_roles: roles(provided),
      claim_basis: mapping.claimBasis[declaration["control-id"]] || "unknown",
      evidence: { state: "not-assessed", observations: [] },
    },
    required: {
      state: required.length ? "confirmed-by-source" : "unknown",
      responsibilities: required,
      responsible_roles: roles(required),
      satisfaction: by.satisfied || [],
    },
    inheritance: {
      state: by.inherited?.length ? "source-declared" : "pending-provider-evidence",
      accepted_claims: by.inherited || [],
    },
    effective_parameters: by["set-parameters"] || declaration["set-parameters"] || [],
    source_refs: {
      declaration_uuid: declaration.uuid,
      statement_uuid: statement.uuid,
      by_component_uuid: by.uuid,
    },
  };
}
export function catalog(fixtures = planFixtures) {
  const mappings = Object.values(fixtures).map((f) => f.mapping);
  const offerings = [...new Set(mappings.map((m) => m.offering))];
  return {
    services: offerings.map((offering) => {
      const plans = mappings.filter((m) => m.offering === offering);
      return {
        id: offering,
        name: offering,
        description: "Synthetic CRM demonstration; no cloud provisioning.",
        bindable: false,
        metadata: {
          oscal_crm: {
            profile: "urn:cloud-sandbox:poc:crm:1",
            href: `/api/crm/offerings/${offering}/plans/${plans[0].plan}`,
          },
        },
        plans: plans.map(({ plan }) => ({
          id: plan,
          name: plan,
          description: `Synthetic ${plan} hosting plan.`,
          metadata: { crm_href: `/api/crm/offerings/${offering}/plans/${plan}` },
        })),
      };
    }),
  };
}
export function componentDetails(id, componentInput = componentDocument, fixtures = planFixtures) {
  const component = componentInput["component-definition"].components.find((c) => c.uuid === id);
  return component
    ? {
        ...component,
        synthetic: true,
        capability_uuids: [
          ...new Set(
            Object.values(fixtures)
              .filter((f) => f.mapping.components.includes(id))
              .map((f) => f.mapping.capability),
          ),
        ],
        source: source("component", componentInput),
        notes: "/api/notes/component-model",
        controls: Object.keys(fixtures).flatMap((plan) =>
          crmForPlan(plan, componentInput, fixtures)
            .controls.filter((r) => r.component_uuid === id)
            .map((r) => ({ plan_id: plan, ...r })),
        ),
      }
    : null;
}
export function crmForPlan(plan, componentInput = componentDocument, fixtures = planFixtures) {
  if (!Object.hasOwn(fixtures, plan)) return null;
  const fixture = fixtures[plan];
  return buildCrm(componentInput, fixture.ssp, fixture.mapping);
}
export function comparePlans(
  from,
  to,
  componentInput = componentDocument,
  fixtures = planFixtures,
) {
  const left = crmForPlan(from, componentInput, fixtures),
    right = crmForPlan(to, componentInput, fixtures);
  if (!left || !right) return null;
  if (left.offering_id !== right.offering_id) return null;
  const key = (row) => `${row.control_id}/${row.statement_id}/${row.component_uuid}`;
  const keys = new Set([...left.controls, ...right.controls].map(key));
  const fields = ["implemented", "required", "effective_parameters", "inheritance"];
  return {
    synthetic: true,
    offering_id: left.offering_id,
    from_plan: from,
    to_plan: to,
    interpretation: "Declaration differences only; not an assessment or compliance ranking.",
    source_documents: { from: left.source_documents, to: right.source_documents },
    changes: [...keys].flatMap((id) => {
      const before = left.controls.find((row) => key(row) === id);
      const after = right.controls.find((row) => key(row) === id);
      const changed_fields = fields.filter(
        (field) => digest(before?.[field] ?? null) !== digest(after?.[field] ?? null),
      );
      return changed_fields.length
        ? [{ row_key: id, changed_fields, before: before || null, after: after || null }]
        : [];
    }),
  };
}
