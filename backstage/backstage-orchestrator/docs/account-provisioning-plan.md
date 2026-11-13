# Backstage Account Provisioning Implementation Plan

## Goal

Provide a Backstage-driven account vending workflow for net-new AWS accounts, GCP projects, and Azure subscriptions. The current backend is a **local-only skeleton**: it validates and records synthetic lifecycle requests but does not provision accounts, register catalog inventory, contact Prowler, or submit provider workflows.

## Target Architecture

1. Backstage Scaffolder captures account requests, ownership, environment, cost center, TTL, and compliance profile.
2. Backstage backend plugin exposes `/api/account-provisioning` with OSB-shaped `/v2/catalog`, `/v2/service_instances/:id`, and `/last_operation` endpoints.
3. Provider adapters submit asynchronous workflows for AWS Organizations, GCP Resource Manager, and Azure subscription vending.
4. Account state is stored in a broker database table with provider operation IDs, owner refs, TTL metadata, budget tags, and lifecycle state.
5. Catalog registration writes or refreshes a Backstage `Resource` entity for each cloud account.
6. Prowler registration resolves scanner credentials from the broker secret store, registers the target account, starts a baseline scan, and records scan status/findings summary on the Resource entity.
7. Scheduled reconciliation polls provider operations, Prowler scan status, budget/TTL state, and catalog inventory freshness.

## Security Model

- Keep all provider credentials outside templates and catalog entities.
- Use managed identity where Azure-hosted, workload identity or service principals for automation, and least-privilege provider roles.
- Store provider credentials, enrollment tokens, and Prowler integration secrets in a secret manager rather than app config.
- Require Backstage authentication and permission checks for account create, update, and delete operations. The current skeleton relies on the existing global authentication policy; it does not yet implement caller-to-owner authorization or catalog group lookup.
- Emit audit events for provisioning, policy updates, scan starts, and deprovisioning.
- Tag or label all provider resources with owner, environment, cost center, request ID, and TTL.

## Provider Adapter Milestones

### AWS

- Create account through AWS Organizations or Account Factory.
- Attach baseline SCPs, IAM Identity Center assignments, CloudTrail, Config, budgets, and required tags.
- Return account ID, partition, management account, and role ARNs needed by Prowler.

### GCP

- Create project under the configured folder, attach billing account, labels, org policies, IAM groups, logging sinks, and budget alerts.
- Return project ID, number, folder, billing account, and scanner service account binding state.

### Azure

- Create or enroll a subscription through the approved subscription vending path.
- Assign management group, policy initiatives, RBAC groups, budgets, diagnostic settings, and tags.
- Use managed identity or service principal credentials at runtime; do not hardcode secrets in code or catalog metadata.
- Return subscription ID, tenant ID, management group, and scanner role assignment state.

## OSB API Contract

- `GET /v2/catalog`: advertise local account-request plans such as `sandbox` and `managed`.
- `PUT /v2/service_instances/:instanceId`: validate and record a local synthetic request. Sandbox requests default to one hour and allow only 1–8 hour integer TTLs.
- `PATCH /v2/service_instances/:instanceId`: update the local sandbox TTL only.
- `DELETE /v2/service_instances/:instanceId`: remove the local synthetic request and record a synthetic deprovision operation.
- `GET /v2/service_instances/:instanceId/last_operation`: report only known local operation state; unknown operations return 404.
- `POST /instances/:instanceId/prowler/scans`: queue a synthetic scan record only for an existing local instance; it does not contact Prowler.

## Backstage Inventory Model

- `System`: `platform-account-provisioning`.
- `Component`: `account-broker-backend`.
- `API`: `platform-account-broker-api`.
- `Resource`: one entity per cloud account, with annotations for provider, account ID, provisioning state, Prowler scan state, latest finding summary, TTL, and owner.

## Local Development

- Run Backstage, Postgres, and a placeholder Prowler API dependency with Docker Compose.
- Start the stack with `docker compose -f docker-compose.local.yml up backstage`.
- The compose service uses the tracked `app-config.local.example.yaml`; copy it to `app-config.local.yaml` only when adding local secrets or personal overrides.
- Exercise the broker skeleton with `curl` against `/api/account-provisioning/v2/catalog` and `/api/account-provisioning/v2/service_instances/:id`.

## Next Build Steps

1. Replace in-memory operations with a database-backed repository.
2. Add Backstage permissions and caller-to-owner authorization for account create/update/delete and Prowler scan operations.
3. Replace provider stubs with AWS, GCP, and Azure adapter packages.
4. Add catalog entity upsert after successful provider account creation.
5. Add Prowler API client and scan status reconciliation.
6. Add tests for request validation, OSB responses, and provider adapter contracts.
