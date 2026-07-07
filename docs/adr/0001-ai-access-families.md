# ADR 0001: Separate AI broker services by access family

## Status

Accepted

## Context

The current AI brokerpaks already expose materially different security models:

- AWS Bedrock provisions a shared substrate and returns per-binding IAM user credentials.
- GCP Vertex AI provisions a shared substrate and returns a service account key JSON at bind time.
- Azure OpenAI provisions a dedicated resource and returns the resource API key at bind time.

Treating these as a single provider-shaped abstraction hides the main operator decision: whether a plan returns a broad secret or a delegated identity grant.

Google and Azure also each have two distinct access families that should remain visible in the catalog:

- Google Gemini API key access versus Google Vertex IAM-backed access.
- Azure OpenAI key access versus Azure Foundry identity and RBAC-backed access.

We still need a stable application-facing binding contract so consumers can read endpoint metadata, auth mode, allowed scope, and credential material consistently across clouds.

## Decision

We will separate AI broker offerings by access family, not just by cloud provider.

The target service families are:

- `aws_bedrock_identity`
- `google_vertex_identity`
- `google_gemini_key`
- `azure_openai_key`
- `azure_foundry_identity`

We will expose a shared normalized binding payload alongside the existing provider-specific outputs. The normalized payload is a consumer contract, not an internal implementation abstraction.

The initial normalized binding payload is:

```json
{
  "version": "v1",
  "provider": "aws|gcp|azure",
  "provisioner_family": "aws_bedrock_identity|google_vertex_identity|google_gemini_key|azure_openai_key|azure_foundry_identity",
  "connection_type": "runtime",
  "endpoint": {
    "base_url": "string",
    "region": "string",
    "api_version": "string|null"
  },
  "access": {
    "mode": "aws_sigv4|gcp_access_token|oauth2_client_credentials|api_key",
    "expires_at": "ISO-8601|null"
  },
  "grant": {
    "kind": "shared_key|scoped_key|service_principal|service_account|assumable_role|impersonation",
    "least_privilege_unit": "resource|project|deployment|model|endpoint",
    "allowed_models": ["string"]
  },
  "credential": {
    "format": "api_key|client_secret|aws_temp_creds|service_account_json|token_exchange",
    "inline": {},
    "secret_ref": "string|null"
  }
}
```

The `inline` field is a transitional addition for the current broker implementations, which still return secret material directly in OSB bindings instead of a separate secret reference.

## Lifecycle rules

For all identity and key families, the broker lifecycle remains:

- `provision`: create the substrate and immutable policy boundary.
- `bind`: create or retrieve tenant-facing access material.
- `unbind`: revoke only the tenant-facing access material.
- `deprovision`: tear down the substrate after bindings are gone.

For key families, the returned secret can still be broad within the tenant resource boundary. Those plans must stay visibly separate from identity-backed plans.

## Consequences

Positive consequences:

- Operators can select plans based on security posture instead of inferring behavior from provider names.
- Applications can adopt one binding parser while the broker keeps separate provisioning logic for keys and identity grants.
- Future Google Gemini key and Azure Foundry identity implementations fit the catalog without overloading existing services.

Trade-offs:

- The catalog will grow into multiple AI families instead of one overloaded service.
- The first normalized payload version is additive and transitional; legacy provider-specific fields will remain until consumers migrate.
- AWS Bedrock and GCP Vertex remain partially transitional because they still return long-lived key material rather than short-lived delegated credentials.

## Implementation plan

Phase 1:

- Add `normalized_binding_json` to existing AWS Bedrock, GCP Vertex AI, and Azure OpenAI bind outputs.
- Preserve all current binding fields so existing consumers do not break.

Phase 2:

- Rename or document current services as `aws_bedrock_identity`, `google_vertex_identity`, and `azure_openai_key` families.
- Update application-side credential readers to prefer `normalized_binding_json` when present.

Phase 3:

- Add `google_gemini_key` as a separate key-backed service family.
- Design and implement `azure_foundry_identity` as a separate RBAC-backed service family.

Phase 4:

- Replace inline secrets with secret references or short-lived delegated credentials where the providers and broker flow support it.
