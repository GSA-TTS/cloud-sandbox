---
title: Cloud Foundry round-trip acceptance runbook
description: Approval-gated procedure for validating the synthetic OSCAL CRM prototype in an authorized Cloud Foundry sandbox
status: draft
tier: 3
last_updated: "2026-11-13"
related_files:
  [
    "poc/oscal-crm/README.md",
    "poc/oscal-crm/server.mjs",
    "poc/oscal-crm/scheduler/adapter.mjs",
    "docs/adr/0006-use-native-oscal-for-crm-api-prototype.md",
  ]
---

# Cloud Foundry round-trip acceptance runbook

## Status: BLOCKED — human approval and dedicated target required

This is a **procedure only**. No Cloud Foundry (CF) command in this document has
been run as part of this increment. In particular, this prototype has not been
deployed, mapped to a route, registered as a service broker, or connected to a
real Open Service Broker API (OSBAPI) client.

The local prototype is read-only and synthetic. A successful deployment or HTTP
request proves deployment wiring only; it does **not** assess OSCAL declarations,
establish control compliance, or authorize a production use.

## Required written approvals

Obtain all of the following before beginning. Record the approver, UTC timestamp,
and approval reference in the acceptance record; do not put tokens or credentials
in that record.

1. **Target authorization:** a dedicated, non-production CF organization and
   space approved for this prototype. A shared development space is not implied
   authorization.
2. **Deployment authorization:** permission to push the application and create
   its temporary route in that target.
3. **Broker decision:** an explicit decision whether this run is application-only
   (read-only catalog/API validation) or includes broker registration. Registration
   is out of scope unless separately approved.
4. **Secret handling:** confirmation that the application token is injected from
   an approved secret store or the platform's approved secret mechanism, never a
   manifest, source file, command history, or acceptance record.
5. **Rollback owner:** a named human accountable for removing the app, route,
   broker registration (if approved), and any associated service artifacts.
6. **Security review:** human review of the deployment manifest, route exposure,
   token injection, and retention of platform logs before execution.

If any item is missing, stop and retain this status as **BLOCKED**.

## Preconditions and safety boundaries

- Use a currently supported CF CLI authenticated as the authorized operator.
- Confirm the CLI target matches the approved API endpoint, organization, and
  dedicated space before any mutating command. Do not infer approval from an
  existing CLI login or target.
- Use a unique, temporary application name and route approved for the sandbox.
  Do not reuse a production hostname.
- Keep the listener private or restrict ingress according to the approved network
  design. The local HTTP-only development listener is not an approved internet
  exposure configuration.
- Configure a 32–128 character URL-safe `CRM_API_TOKEN` through the approved
  secret mechanism. Do not echo, log, commit, or paste its value.
- Set `CRM_CONTEXT_MANIFEST` only to an approved synthetic manifest packaged with
  the application. Do not upload government, production, or CUI data.
- Do not run provision, update, bind, unbind, deprovision, or broker catalog
  mutation calls against CF. The prototype's local in-memory mock lifecycle is
  not a registered broker and is not authorization to run those operations.

## Proposed acceptance procedure — do not execute until approved

### 1. Establish and record the authorized target

The authorized operator performs the platform's approved login flow and selects
the approved target. Before deployment, capture sanitized evidence of the target
identity (API endpoint, organization, and space), omitting usernames, tokens, and
any sensitive endpoint details from public records.

Stop if the selected organization or space differs from the written approval.

### 2. Review the deployment inputs

Human reviewers verify all of the following before a push:

- the application executes `node poc/oscal-crm/server.mjs` (or an equivalently
  reviewed packaged command);
- `CRM_API_TOKEN` comes from the approved secret mechanism;
- the manifest and environment do not contain token values;
- the bound route is limited to the approved sandbox audience and uses approved
  TLS termination; and
- no service broker registration is included unless the broker decision explicitly
  authorizes it.

Run the repository verifier before packaging:

```sh
node poc/oscal-crm/verify.mjs
```

Record its pass/fail output and commit identifier in the acceptance record.

### 3. Deploy only the reviewed application

The authorized operator may push the reviewed artifact to the approved dedicated
space after the approvals above are recorded. Capture only sanitized platform
events: application identifier, package revision, desired/running instances,
route identifier, and timestamps. Do not capture environment variables, request
authorization headers, or token values.

If the deployment fails, stop, preserve sanitized error evidence, and invoke the
rollback procedure. Do not retry silently.

### 4. Run the read-only acceptance checks

Using an approved test client and a token retrieved only through the approved
secret mechanism, verify these HTTPS requests against the approved route:

| Check                                                                | Expected result                               |
| -------------------------------------------------------------------- | --------------------------------------------- |
| Authenticated `GET /health`                                          | `200` with synthetic status                   |
| Authenticated `GET /v2/catalog`                                      | `200`; discovery only, no provisioning claim  |
| Authenticated `GET /api/crm/offerings/managed-hosting/plans/managed` | `200`; declared provider/customer split       |
| Authenticated `GET /api/crm/compare/managed/enhanced`                | `200`; declaration comparison, not assessment |
| Authenticated `GET /api/oscal/component` and `GET /api/oscal/ssp`    | `200`; native synthetic documents             |
| Request without bearer authentication                                | `401`                                         |
| Unsupported method, such as `POST /v2/catalog`                       | `405`                                         |

For each request, retain the UTC timestamp, method, path, response status, and
redacted response digest. Do not retain bearer tokens, tenant headers, or full
responses if they contain information not approved for the record. Confirm that
the application audit logs likewise omit tokens and request bodies.

### 5. Optional broker-registration gate

Do **not** register a broker as part of the application-only acceptance run. If
broker registration is separately approved, create a new change record that names
the broker artifact, catalog exposure, access controls, rollback owner, and
OSBAPI acceptance tests. This runbook does not authorize that work.

### 6. Determine the outcome

Mark the run **PASS** only if the application is healthy, every read-only check
has the expected result, the route and secret handling match approvals, and the
rollback owner confirms cleanup readiness. Otherwise mark it **FAIL** or
**BLOCKED**, state the observed evidence, and do not claim a real broker or
compliance validation.

## Rollback

The named rollback owner must:

1. Stop and delete the temporary application and its temporary route from the
   approved sandbox.
2. Remove any application-specific service bindings or routes created for this
   run, after preserving approved, sanitized evidence.
3. If separately authorized broker registration occurred, unregister the broker
   and remove only the artifacts created by this run.
4. Revoke or rotate the injected test token through the approved secret mechanism.
5. Record cleanup completion, residual artifacts, and any follow-up owner in the
   acceptance record.

Do not delete shared spaces, shared routes, shared services, or artifacts not
created for this approved run.

## Acceptance record template

```text
Run ID:
UTC start / finish:
Approved CF target reference:
Deployment approver / reference:
Broker decision (application-only | registered) / reference:
Secret mechanism confirmed by:
Rollback owner:
Security reviewer:
Repository commit:
Verifier result:
Sanitized deployment evidence:
Read-only check results and response digests:
Rollback result or retained-artifact justification:
Final outcome (PASS | FAIL | BLOCKED):
```

## Out of scope

- Production deployment or production data.
- CF organization, space, role, route-domain, network-policy, or credential
  administration.
- Real broker provisioning, service-instance lifecycle operations, bindings, or
  a real OSBAPI client.
- Any claim that provider declarations constitute assessment evidence or an ATO
  decision.
