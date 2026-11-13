---
title: Cloud Foundry round-trip runbook (WP6)
description: Steps to exercise the synthetic CRM context through a real Cloud Foundry and OSBAPI client path. Not executed; requires human approval.
status: draft
tier: 3
last_updated: "2026-11-13"
related_files:
  ["poc/oscal-crm/README.md", "docs/adr/0006-use-native-oscal-for-crm-api-prototype.md"]
---

# Cloud Foundry round-trip runbook (WP6)

**Status: BLOCKED.** Nothing in this runbook has been executed. Each step that
changes a Cloud Foundry space, service broker, route, or credential needs
explicit approval from a human maintainer before it runs. The `cf` CLI is
authenticated to a shared space, so do not assume a target is safe to change.

## Purpose

Issue #83 requires a real round-trip, not only loopback proof. The goal is to
show that the standard OSBAPI discovery (`/v2/catalog`) still parses for a
legacy client, that the opt-in CRM link and per-plan document digests survive
the platform, and that the authenticated context route is reachable from a
platform-hosted client. This run does not prove the CRM is correct, and it
does not prove authorization.

## Preconditions (all required)

1. A named, dedicated sandbox space approved for this prototype. Not `dev`
   unless the space owner approves in writing.
2. The pinned `poc/oscal-crm` commit deployed, with `CRM_API_TOKEN` supplied as
   a Cloud Foundry user-provided service or environment variable from an
   approved secret store. Never placed in the manifest or in logs.
3. A written decision on whether the broker is registered at all. The
   read-only `/v2/catalog` check does not require registration.
4. Rollback owner named. Rollback is `cf delete` of the prototype app and
   removal of any route created for it.

## Steps (to run only after approval)

1. **Read-only checks (safe):** `cf target`, `cf apps`, `cf services`. Record
   the output in the PR transcript. Do not record credentials.
2. **Deploy (approval required):** push the prototype with
   `CRM_CONTEXT_MANIFEST` pointing at the exported demo manifest, bound to
   `127.0.0.1` inside the container only if the platform supports it. If the
   platform requires `0.0.0.0`, stop and get a security decision first.
3. **Discovery (legacy client):** `curl -H "Authorization: Bearer $TOKEN"`
   against the app route for `/v2/catalog`. Confirm HTTP 200 and that the
   standard `services` shape is present. Confirm `metadata.oscal_crm` and
   `crm_documents` are present and that `bindable` is `false`.
4. **Context route:** request
   `/api/crm/context/managed-hosting/managed/demo-instance` with
   `X-CRM-Tenant: demo-tenant`. Confirm `context_digest` matches a second
   request, and that a stale `If-Match` returns 409.
5. **Negative paths:** missing token → 401; wrong tenant → 404; POST → 405.
6. **Teardown:** `cf delete` the prototype app and any temporary route. Confirm
   with `cf apps`.

## Recording the result

Attach the transcript to the PR with each step marked PASS, FAIL, or BLOCKED.
A FAIL must not be edited out. Mark #83's real-CF acceptance gate as satisfied
only if steps 1–6 all pass and a human reviewer signs off.

## Not in scope

- Real OSBAPI provisioning, bindings, or service keys.
- Production or multi-tenant use.
- Any change to the shared `dev` space without written approval.
