---
title: Harden the local account provisioning skeleton
description: Bound local account-request lifecycle behavior before any provider adapter is introduced
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
    "backstage/backstage-orchestrator/packages/backend/src/plugins/accountProvisioning.ts",
    "backstage/backstage-orchestrator/packages/backend/src/plugins/accountProvisioning.test.ts",
    "backstage/backstage-orchestrator/docs/account-provisioning-plan.md",
  ]
---

# Harden the local account provisioning skeleton

## Context and Problem Statement

The Backstage account-provisioning plugin was a permissive skeleton that could
misrepresent queued local operations as provider work. Before adding provider
adapters, the local model must fail closed, validate lifecycle input, and avoid
claims that accounts, catalog inventory, or Prowler scans exist.

## Decision Outcome

Use a testable in-memory repository with strict request allowlists, documented
service/plan selection, idempotent instance requests, conflict rejection,
operation lookup that returns 404 when unknown, and scan stubs limited to existing
local instances. Sandbox requests default to one hour and permit only integer
TTLs from one through eight hours. Managed requests reject TTLs pending an
approved retention policy.

This is not an authorization system. The existing Backstage authentication policy
protects the route, but caller-to-owner authorization, group lookup, persistence,
provider workflows, catalog upsert, Prowler integration, and real account
creation remain unimplemented and require separately approved designs.

## Consequences

The skeleton becomes safer to demonstrate and test, but still loses all state on
restart and cannot prove provider compatibility. It performs no network or cloud
operation. Future adapters require secret management, least-privilege identities,
provider approval, durable lifecycle records, permission checks, audit design,
and rollback planning.
