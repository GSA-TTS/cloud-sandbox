---
title: Use an in-memory mock broker for the CRM demo
description: Demonstrate synthetic OSBAPI lifecycle and account creation without Cloud Foundry integration
status: proposed
tier: 2
date: "2026-11-13"
last_updated: "2026-11-13"
decision_makers: ["Cloud Sandbox maintainers", "Security reviewers"]
category: Architecture and Data Modeling
nist_controls: ["AC-3", "AC-6", "AU-12", "CM-3", "SA-11", "SI-10"]
impact_level: moderate
ato_relevance: no
risk_treatment: mitigate
related_files:
  [
    "poc/oscal-crm/broker.mjs",
    "poc/oscal-crm/server.mjs",
    "poc/oscal-crm/test/broker.test.mjs",
    "poc/oscal-crm/README.md",
  ]
---

# Use an in-memory mock broker for the CRM demo

## Context and Problem Statement

The CRM prototype needs a demonstrable service-instance and account lifecycle,
but Cloud Foundry does not currently support the required CRM model changes. The
approved scope is a local mock implementation only; it must not imply platform
integration, broker registration, or a real account authority.

## Decision Drivers

- Demonstrate a narrow OSBAPI-shaped lifecycle without cloud access.
- Keep synthetic CRM declarations separate from provisioning and assessment claims.
- Apply least privilege through distinct CRM-view and mock-broker credentials.
- Avoid persistence, PII, passwords, external identity providers, and new dependencies.
- Provide auditable, redacted local events and deterministic test coverage.

## Considered Options

1. Wait for Cloud Foundry backend support and demonstrate only the read-only catalog.
2. Add custom CRM fields to existing Cloud Foundry broker responses.
3. Implement a bounded, in-memory local mock broker beside the CRM prototype.

## Decision Outcome

Choose option 3. `poc/oscal-crm/broker.mjs` models synthetic provision,
last-operation, deprovision, and account-create/read interactions in memory for
the process lifetime only. Account records contain only an opaque generated ID,
a caller-provided non-sensitive display label, an active status, and a synthetic
marker. There are no passwords, email addresses, external identities, or role grants.

Mock lifecycle routes require `MOCK_BROKER_TOKEN`, which must differ from the
existing read-only `CRM_API_TOKEN`. Account disable is idempotent; disabled
accounts cannot receive new bindings. A binding returns only an opaque synthetic
account reference, never a password, bearer token, or connection string. Request bodies are bounded and allowlisted;
audit events contain timestamps, event type, status, and a synthetic marker, but
no tokens, request body, account label, or identity. The implementation does not
register a broker, call Cloud Foundry, store records, or claim OSBAPI conformance.

## Consequences

Positive: the demo can show a complete local lifecycle and safely distinguish
provisioning state from CRM evidence. Tests cover authentication separation,
idempotent provision, malformed input, account isolation, cleanup, and audit-log redaction.

Negative: all state disappears when the process stops; the mock is intentionally
not a production broker, persistence layer, identity system, or a substitute for
Cloud Foundry compatibility testing. A future real integration requires a new
reviewed change record for broker registration, platform authorization,
credential storage, TLS, tenant identity, lifecycle semantics, and rollback.

## Verification and Tracking

Run `node poc/oscal-crm/verify.mjs` to execute formatting, secret scanning,
syntax checks, native OSCAL validation, broker tests, and live loopback proof.
This decision does not close #82 or #83 and does not satisfy their real-broker or
CF acceptance gates. Rollback removes the mock module and routes through normal
review; no cloud resource exists to clean up.
