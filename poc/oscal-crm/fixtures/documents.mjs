// Synthetic OSCAL 1.1.3 examples. No assertion describes a real service.
export const uuid = (n) => `10000000-0000-4000-8000-${String(n).padStart(12, "0")}`;
const metadata = (title) => ({
  title: `SYNTHETIC: ${title}`,
  "last-modified": "2026-10-28T00:00:00Z",
  version: "0.1.0",
  "oscal-version": "1.1.3",
  roles: [
    { id: "provider-operator", title: "Synthetic provider operator" },
    { id: "customer-owner", title: "Synthetic customer owner" },
  ],
});
const roles = (id) => [{ "role-id": id }];
export const controls = [
  {
    id: "ac-2",
    title: "Account management",
    state: "implemented",
    basis: "provider-default",
    provider: "Provider creates, disables and reviews hosting-plane service accounts.",
    required:
      "Customer defines application account types, removes departed users and reviews application access every 30 days.",
    parameter: { "param-id": "ac-2_prm_1", values: ["30 days"] },
  },
  {
    id: "au-2",
    title: "Event logging",
    state: "partial",
    basis: "explicit-plan-configuration",
    provider:
      "Provider collects hosting-plane audit events; application event coverage is outside this component.",
    required:
      "Customer selects application audit events and configures an application log destination.",
    parameter: { "param-id": "au-2_prm_1", values: ["authentication and authorization events"] },
  },
  {
    id: "sc-13",
    title: "Cryptographic protection",
    state: null,
    basis: "unknown",
    provider:
      "Provider cryptographic implementation has not been established in this synthetic source.",
    required:
      "Customer obtains provider cryptographic evidence and documents protection of application data.",
  },
];
const requirement = (c, i) => ({
  uuid: uuid(100 + i),
  "control-id": c.id,
  description: c.provider,
  statements: [
    {
      uuid: uuid(200 + i),
      "statement-id": `${c.id}_smt.a`,
      description: c.provider,
      "responsible-roles": roles("provider-operator"),
    },
  ],
  ...(c.parameter ? { "set-parameters": [c.parameter] } : {}),
});
export const componentDocument = {
  "component-definition": {
    uuid: uuid(1),
    metadata: metadata("Managed hosting component definition"),
    components: [
      {
        uuid: uuid(2),
        type: "service",
        title: "Synthetic managed hosting",
        description: "Hosting-plane identity and logging; excludes customer application logic.",
      },
    ],
    capabilities: [
      {
        uuid: uuid(3),
        name: "Managed hosting offering",
        description: "Synthetic managed plan. Not an authorized real offering.",
        "incorporates-components": [
          { "component-uuid": uuid(2), description: "Hosting-plane service." },
        ],
        "control-implementations": [
          {
            uuid: uuid(4),
            source: "urn:example:baseline",
            description: "Synthetic declarations, not independently verified.",
            "implemented-requirements": controls.map(requirement),
          },
        ],
      },
    ],
  },
};
function byComponent(c, i) {
  return {
    uuid: uuid(400 + i),
    "component-uuid": uuid(2),
    description: c.provider,
    ...(c.state ? { "implementation-status": { state: c.state } } : {}),
    ...(c.parameter ? { "set-parameters": [c.parameter] } : {}),
    export: {
      description: "Synthetic shared responsibility split; not acceptance of inheritance.",
      provided: [
        {
          uuid: uuid(500 + i),
          description: c.provider,
          "responsible-roles": roles("provider-operator"),
        },
      ],
      responsibilities: [
        {
          uuid: uuid(600 + i),
          "provided-uuid": uuid(500 + i),
          description: c.required,
          "responsible-roles": roles("customer-owner"),
        },
      ],
    },
  };
}
export const sspDocument = {
  "system-security-plan": {
    uuid: uuid(10),
    metadata: metadata("Consumer CRM example"),
    "import-profile": { href: "urn:example:baseline" },
    "system-characteristics": {
      "system-ids": [{ id: "synthetic-crm-demo" }],
      "system-name": "Synthetic CRM demo",
      description: "Non-sensitive demonstration only.",
      "system-information": {
        "information-types": [
          {
            uuid: uuid(11),
            title: "Synthetic test records",
            description: "Fabricated non-sensitive data, not government system information.",
          },
        ],
      },
      status: { state: "under-development" },
      "authorization-boundary": { description: "Local demonstration, no authorization claim." },
    },
    "system-implementation": {
      users: [
        {
          uuid: uuid(12),
          title: "Synthetic customer role",
          "role-ids": ["customer-owner"],
          "authorized-privileges": [
            { title: "Review", "functions-performed": ["Review synthetic CRM"] },
          ],
        },
      ],
      components: [
        {
          uuid: uuid(2),
          type: "service",
          title: "Synthetic managed hosting",
          description: "Provider component referenced by the consumer.",
          status: { state: "operational" },
        },
      ],
    },
    "control-implementation": {
      description:
        "Source-declared scope; no accepted inheritance or satisfied residual is asserted.",
      "implemented-requirements": controls.map((c, i) => ({
        uuid: uuid(300 + i),
        "control-id": c.id,
        statements: [
          {
            uuid: uuid(700 + i),
            "statement-id": `${c.id}_smt.a`,
            "by-components": [byComponent(c, i)],
          },
        ],
      })),
    },
  },
};
export const registry = {
  offering: "managed-hosting",
  plan: "managed",
  capability: uuid(3),
  controlImplementation: uuid(4),
  component: uuid(2),
  instances: [{ id: "demo-instance", tenant: "demo-tenant" }],
  claimBasis: Object.fromEntries(controls.map((c) => [c.id, c.basis])),
};

// Scope each declaration to its actual incorporated component.
const componentIds = [uuid(20), uuid(21), uuid(2)];
const definition = componentDocument["component-definition"];
definition.components.push(
  {
    uuid: uuid(20),
    type: "service",
    title: "Synthetic identity service",
    description: "Hosting-plane account lifecycle. Excludes customer application accounts.",
  },
  {
    uuid: uuid(21),
    type: "service",
    title: "Synthetic audit service",
    description: "Hosting-plane event collection; plan determines application routing support.",
  },
);
definition.capabilities[0]["incorporates-components"] = definition.components.map((c) => ({
  "component-uuid": c.uuid,
  description: c.description,
}));
const consumer = sspDocument["system-security-plan"];
consumer["system-implementation"].components = definition.components.map((c) => ({
  ...c,
  status: { state: "operational" },
}));
consumer["control-implementation"]["implemented-requirements"].forEach((r, i) => {
  r.statements[0]["by-components"][0]["component-uuid"] = componentIds[i];
});
registry.components = componentIds;

export const enhancedSspDocument = structuredClone(sspDocument);
enhancedSspDocument["system-security-plan"].uuid = uuid(30);
enhancedSspDocument["system-security-plan"].metadata.title = "SYNTHETIC: Enhanced consumer CRM";
const enhancedRequirements =
  enhancedSspDocument["system-security-plan"]["control-implementation"]["implemented-requirements"];
const enhancedDeclarations = structuredClone(
  definition.capabilities[0]["control-implementations"][0],
);
enhancedDeclarations.uuid = uuid(31);
enhancedDeclarations.description = "Enhanced plan declarations, not independently assessed.";
enhancedDeclarations["implemented-requirements"].forEach((r, i) => {
  r.uuid = uuid(800 + i);
  r.statements[0].uuid = uuid(810 + i);
});
const auditBy = enhancedRequirements[1].statements[0]["by-components"][0];
auditBy.description =
  "Provider collects hosting-plane events and supplies a managed application log destination; customer event selection remains outside provider scope.";
auditBy["implementation-status"].state = "implemented";
auditBy.export.provided[0].description = auditBy.description;
auditBy.export.responsibilities[0].description =
  "Customer selects application audit events and verifies delivery to the provided managed destination.";
const accountBy = enhancedRequirements[0].statements[0]["by-components"][0];
accountBy["set-parameters"][0].values = ["7 days"];
accountBy.export.responsibilities[0].description =
  "Customer defines application account types, removes departed users and reviews application access every 7 days.";
enhancedDeclarations["implemented-requirements"][0]["set-parameters"][0].values = ["7 days"];
enhancedDeclarations["implemented-requirements"][1].description = auditBy.description;
enhancedDeclarations["implemented-requirements"][1].statements[0].description = auditBy.description;
definition.capabilities[0]["control-implementations"].push(enhancedDeclarations);
export const enhancedRegistry = {
  ...registry,
  plan: "enhanced",
  controlImplementation: uuid(31),
  documentName: "ssp-enhanced",
};
registry.documentName = "ssp";
export const planFixtures = {
  managed: { ssp: sspDocument, mapping: registry },
  enhanced: { ssp: enhancedSspDocument, mapping: enhancedRegistry },
};
