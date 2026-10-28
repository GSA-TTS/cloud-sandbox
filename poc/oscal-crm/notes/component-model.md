---
title: Native component model and CRM implementation notes
description: How capability declarations and consumer SSP responsibilities become side-by-side API rows
status: draft
tier: 3
last_updated: "2026-10-28"
related_files:
  ["poc/oscal-crm/README.md", "docs/adr/0006-use-native-oscal-for-crm-api-prototype.md"]
---

# Component model: what is implemented versus what is required

## Plan composition increment

Managed and Enhanced incorporate three native components: hosting (`…000002`),
identity (`…000020`) and audit (`…000021`). AC-2 rows reference identity; AU-2
references audit; SC-13 references hosting. The top-level `component_uuid` is
the offering's hosting anchor; each CRM row identifies the actual implementing
component and must resolve to an incorporated component in the native documents.

Enhanced selects a second native capability control-implementation UUID and a
separate consumer SSP. It declares the audit destination provided, while retaining
customer event selection/delivery verification. Identity reviews change to 7 days.
Comparison keys include control, statement and component, not control alone.
Both plans remain unassessed; changed declarations never become observed results.

AI-assisted modeling notes; all example assertions are synthetic. A component
implements a **scope of a control**, not necessarily the entire customer system
control. Therefore the CRM must retain the implementation scope and residual
customer duty instead of reducing a control to one green badge.

## Native structure

### Data flow: native documents to CRM rows

This diagram describes the running document-backed prototype with synthetic
defaults and an optional local manifest. Component-definition declares
capabilities; the consumer SSP supplies the machine-readable responsibility split.

```mermaid
flowchart TD
    Core["Pinned core OSCAL 1.1.3 schemas"] --> Cache["Local schema cache"]
    Manifest["Operator-selected local manifest"] --> Loader["Bounded local JSON loader"]
    Loader --> Integrity["Path containment and byte digest checks"]
    Integrity -->|"Validated local documents"| Validate
    Manifest --> Registry
    CD["Synthetic component-definition"] --> Validate["Startup schema and reference validation"]
    SSP["Synthetic consumer SSPs: Managed and Enhanced"] --> Validate
    Cache --> Validate
    Validate -->|"Valid documents"| API["Loopback CRM API"]
    Validate -->|"Invalid documents"| Stop["Abort startup"]
    Registry["Offering and plan registry"] --> Resolve["Resolve capability and control implementation"]
    CD --> Resolve
    Resolve --> Join["Match control, statement and incorporated component"]
    SSP --> Join
    Join --> Rows["Project provider declarations and customer requirements"]
    Rows --> Contract["Strict CRM response validation"]
    Contract --> API
    API --> Viewer["Browser viewer or API client"]
    API --> Native["Native OSCAL document retrieval"]
    API --> Audit["Redacted UTC request audit events"]
```

Schema validation and projection validation serve different purposes: native
schemas check OSCAL structure, while projection validation checks the API
contract. Neither establishes that a declared implementation was assessed.

### Model boundaries: provider does versus customer must do

```mermaid
flowchart LR
    subgraph Definition["Native component-definition"]
        Capability["Offering capability"] --> Incorporated["Incorporated components"]
        Capability --> CI["Plan control implementation"]
        CI --> Declaration["Implemented requirements and statements"]
    end
    subgraph Consumer["Native consumer SSP"]
        Statement["Control statement"] --> By["By-component record"]
        By --> Export["Export"]
        Export --> Provided["Provided: provider implementation scope"]
        Export --> Responsibility["Responsibilities: customer duties"]
        Responsibility -->|"provided-uuid reference"| Provided
        By --> Inherited["Inherited: source-authored acceptance only"]
        By --> Satisfied["Satisfied: source-authored residual satisfaction only"]
        Inherited -->|"provided-uuid reference"| Provided
        Satisfied -->|"responsibility-uuid reference"| Responsibility
    end
    Incorporated -. "component-uuid reference" .-> By
    Declaration -. "control and statement match" .-> Statement
    Provided --> CRM["Side-by-side CRM row"]
    Responsibility --> CRM
    By --> CRM
```

`inherited` and `satisfied` are optional source records, absent in the current
fixtures. The API does not create them from the existence of a provider claim.
Evidence remains `not-assessed`; missing status or customer facts stay unknown.

### API exchanges: discovery, CRM and component detail

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Browser as Browser viewer
    participant API as Loopback API
    participant Projection as CRM projection
    participant Sources as Validated context documents
    User->>API: GET / (no token)
    API-->>Browser: Public static viewer shell, no CRM data
    User->>Browser: Enter local bearer token and Connect
    Note over Browser: Token held in memory and input cleared
    Browser->>API: GET /v2/catalog with bearer token
    API-->>Browser: Available offerings and plans from loaded context
    Browser->>API: GET plan CRM with Authorization bearer token
    API->>API: Authenticate and validate allowlisted path
    API->>Projection: Resolve selected offering and plan
    Projection->>Sources: Read declarations and consumer responsibility records
    Sources-->>Projection: Native statements, UUIDs, roles and parameters
    Projection->>Projection: Join references and validate response contract
    Projection-->>API: Synthetic CRM with source digests
    API-->>Browser: 200 JSON, no-store
    loop Each component-scoped control row
        Browser->>API: GET /api/components/{uuid} with bearer token
        API-->>Browser: Component detail and source references
    end
    Browser->>API: GET /api/notes/component-model with bearer token
    API-->>Browser: JSON-wrapped Markdown notes
    Browser-->>User: Provider implements versus customer must implement
    Note over Browser,API: Available plans are discovered from the loaded context
```

API clients can discover the plan list using authenticated `GET /v2/catalog`,
then follow each plan's `metadata.crm_href`. The browser now discovers offerings
and plans from that catalog. Notes are currently displayed as Markdown text,
including Mermaid source; the viewer does not include a Mermaid renderer.

### Instance isolation and failure exchanges

```mermaid
sequenceDiagram
    participant Client
    participant API as Loopback API
    participant Registry as Synthetic instance registry
    Client->>API: GET instance CRM without valid bearer token
    API-->>Client: 401 Authentication required
    Client->>API: GET instance CRM with valid token and tenant header
    API->>Registry: Resolve instance and compare configured tenant scope
    alt Missing instance, missing tenant or wrong tenant
        Registry-->>API: No accessible context
        API-->>Client: 404 Context not found
    else Instance belongs to configured demo tenant
        Registry-->>API: Matching fixture context
        API-->>Client: 200 CRM with synthetic effective-parameter snapshot
    end
    Client->>API: Authenticated GET with query parameters
    API-->>Client: 400 Invalid path
    Client->>API: Authenticated non-GET request
    API-->>Client: 405 Read-only API
    Note over Client,API: Tenant header is a scope check, not independent identity proof
```

### Plan comparison exchange

```mermaid
sequenceDiagram
    participant Client as Viewer or API client
    participant API as Loopback API
    participant Projection as CRM projection
    Client->>API: GET /api/crm/compare/managed/enhanced with bearer token
    API->>Projection: Project Managed CRM
    Projection-->>API: Managed component-scoped rows and document digests
    API->>Projection: Project Enhanced CRM
    Projection-->>API: Enhanced component-scoped rows and document digests
    API->>API: Match rows by control, statement and component
    API->>API: Compare implementation, requirements, parameters and inheritance
    API-->>Client: 200 Changed fields plus before/after rows and source digests
    Note over Client,API: Declaration differences only, not compliance ranking
```

The current comparison reports AC-2 review-period/customer-duty changes and AU-2
provider-scope/customer-duty changes. SC-13 remains unknown in both plans. A
missing plan returns 404 rather than an empty comparison implying equivalence.

1. **Offering → capability.** The managed-hosting offering selects a native
   component-definition capability by UUID.
2. **Plan → control implementation.** An explicit fixture registry maps the
   managed plan to a capability control-implementation UUID. This mapping is
   projection metadata, not a new native OSCAL assembly.
3. **Resource → component.** The capability incorporates the hosting-plane
   service through `incorporates-components[].component-uuid`.
4. **Declared implementation → implemented requirement / statement.** Preserve
   control IDs, statement IDs, narratives, roles and set-parameters.
5. **CRM split → consumer SSP by-component export.** Machine-readable provider
   statements belong in `export.provided`; customer duties belong in
   `export.responsibilities`. Responsibilities retain `provided-uuid` links.
   These assemblies do **not** belong inside component-definition.
6. **Acceptance → inherited / satisfied.** Inheritance and customer satisfaction
   require their own source-authored UUID references. None are asserted by this
   fixture; the API reports pending provider evidence and an empty satisfaction
   list, not automatic acceptance.

## Detailed example component

**Synthetic managed hosting**, UUID
`10000000-0000-4000-8000-000000000002`, includes provider hosting-plane service
account management and audit collection. It excludes application authorization,
application account lifecycle and application-specific event selection. The
provider operator owns hosting-plane duties; the customer owner owns residuals.

AC-2 declares hosting-plane account management implemented; the customer must
define application account types, remove departed users and review access every
30 days. AU-2 declares partial scope: hosting events exist, but application event
selection and routing remain required. SC-13 is unknown, so the CRM explicitly
requires provider evidence rather than fabricating cryptographic compliance.

The API returns the raw OSCAL status separately from `claim_basis`, evidence
state, customer obligations and inheritance acceptance. No system-operational
status is mapped to control implementation status. A successful HTTP request
means the projection was retrieved, not that a control was tested.

## Provenance and context

- Core schema reference: `GSA-TTS/oscal-vault-core` revision
  `1a127cf611d10aaf40a1f0e36fdc77172d5da564`, OSCAL 1.1.3. Currently private;
  public release TBD. The interoperability notes linked by its README are not
  in that revision's tree.
- Modeling guidance: `GSA-TTS/oscal-vault` revision
  `06763fb02b5913616cd6e501eb17f6d002b310f9`,
  `docs/osbapi-backstage-interop/capabilities-as-osbapi-offerings.md`. Its prose
  distinguishes native assemblies correctly; illustrative diagrams incorrectly
  place exports under component-definition, so schemas govern implementation.
- Additional context: `GSA-TTS/TTSE-petrified-forest-sspp` revision
  `812403d287d590d1a224f37ea2342e1bea6b35cc`,
  `schemas-local/system-crm.schema.json`. Its separation of tenant obligations,
  provider evidence, inheritance acceptance and implementation state informed
  this projection. It is private; no system CRM data was imported or republished.
- Scope and acceptance: cloud-sandbox #82 and #83. Native schema validity is
  tested here; control assertions and actual CF compatibility still need the
  separately tracked acceptance reviews.

## Integrity and security

### Scheduled retrieval is not assessment

The scheduler contract tests and Mermaid exchange are documented in
`poc/oscal-crm/README.md` under **OCF scheduler interaction tests**. They pin the
OCF scheduler's HTTP call behavior to revision
`8f070f0aed8c622ec22b82a053a11af37d1de4dc` and distinguish a mocked dispatcher
from real loopback API requests. A direct POST is rejected by this read-only CRM;
a separate test-only trigger adapter makes authenticated GETs, validates the
projection/digests and returns `assessed: false`. No scheduler or adapter outcome
changes provider status, inherited acceptance or residual satisfaction.

Canonical fixture serialization is SHA-256 hashed and references both native
documents. A digest is an integrity check, not a signature or authorization.
Documents and notes are retrieved only from local allowlisted routes, never a
caller-supplied URI. No untrusted URLs are dereferenced. One environment token
authorizes only the synthetic tenant; a tenant header alone never grants access.
Logs omit tokens, query values, bodies and user identities.
