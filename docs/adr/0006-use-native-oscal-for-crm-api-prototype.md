---
title: Use native OSCAL for a local CRM API prototype
description: Separate component capability declarations from consumer responsibilities and assessment evidence
status: proposed
tier: 2
date: "2026-10-28"
last_updated: "2026-10-28"
decision_makers: ["Cloud Sandbox maintainers", "Security reviewers"]
category: Architecture and Data Modeling
nist_controls: ["AC-3", "AU-12", "CM-3", "SA-11", "SI-10"]
impact_level: moderate
ato_relevance: no
risk_treatment: mitigate
related_files: ["poc/oscal-crm/README.md", "poc/oscal-crm/notes/component-model.md"]
---

# Use native OSCAL for a local CRM API prototype

## Context and Problem Statement

Issues #82/#83 require a CRM that exposes provider implementations alongside
customer duties without making custom OSBAPI provision fields authoritative.
The user approved a scoped synthetic API build and loopback demonstration.
This is an AI-assisted proposed architectural record, not production approval.

## Decision Drivers

- Native OSCAL 1.1.3 structures and stable UUID references.
- Distinguish declared implementations, customer requirements, acceptance and
  observed evidence; missing facts stay unknown.
- Preserve existing broker/Backstage work and avoid new dependencies.
- Refer to currently private core without republishing restricted system data.

## Considered Options

1. Embed CRM and private narratives in broker provision responses.
2. Publish native component declarations plus a separate authenticated CRM
   projection from component-definition and consumer SSP records.
3. Present only a static responsibility spreadsheet.

## Decision Outcome

Prototype option 2 in isolated `poc/oscal-crm/`. Node built-in HTTP/test tools
and existing Ajv validate synthetic native documents. Component capabilities
declare offerings; consumer SSP by-component exports hold provided statements
and customer responsibilities. Preserve source status and parameter values.
Plan mappings and claim basis remain explicit projection metadata.

Pin schema inputs to core revision
`1a127cf611d10aaf40a1f0e36fdc77172d5da564`; record notes and SSPP schema context
separately in component-model notes. Download only official schema files into
ignored local cache. No dependency install, submodule update or CI change.

## Consequences

The approved second increment adds a same-origin browser viewer and comparison
of two synthetic plans composing three components. Public static assets contain
no control data; bearer-authenticated API retrieval stays unchanged. Browser
tokens remain in memory and output uses textContent with a restrictive CSP.
Each row references its actual component; differences retain provider scope,
customer obligations and parameters without ranking compliance. No dependencies
or cloud capabilities were added.

Positive: real HTTP proof, schema-valid native documents, testable reference
integrity, and no accidental inference of authorization from provisioning.

Negative: one synthetic tenant/plan, no persistence or real assessment pipeline,
and authenticated core access needed for initial schema bootstrap.

Security: environment-supplied bearer token, loopback-only synthetic HTTP,
sanitized audit events and fail-closed missing context. Network deployment
requires a separate approved TLS/identity/rate-limit design. No public catalog
contains credentials or private SSP prose.

## Verification and Tracking

The approved scheduler test increment adds a test model of OCF HTTP calls,
pinned to `8f070f0aed8c622ec22b82a053a11af37d1de4dc`, and a test-only empty-POST
adapter using a separate CRM bearer token. The read-only CRM still rejects direct
POSTs. Actual loopback GET exchanges validate declarations and document digests;
mock execution success never becomes assessment success. Start-recording failure,
authentication, tenant scope, repeated delivery, transport and malformed-response
tests are registered in the one-command verifier. No upstream dependency,
scheduler deployment, cron engine, database or cloud grants are introduced.
Real scheduler integration remains tracked by #79; these tests do not close it.

The approved document-loading increment selects local JSON with a strict manifest,
byte digests, bounded file sizes/nesting and symlink-aware path containment. Native
schemas, reference checks and CRM projection validation run before startup.
Manifest documents remain synthetic-only; no private system SSP imports or remote
URI resolution. API routes and catalog-driven viewer discovery use the loaded
snapshot. Restart is required for source changes; no upload or reload endpoint.

Use `node poc/oscal-crm/verify.mjs` for schema/reference checks, unit/HTTP tests
and live loopback responses. Scope remains tracked by #82/#83; do not close
those issues from local mock proof. Real CF compatibility and human acceptance
remain their existing gates. Rollback stops the listener and reverts only these
scoped artifacts through normal review; no cloud resources exist to destroy.
