# Cloud Sandbox Operations Runbook

This runbook covers day-2 operations for Cloud Sandbox broker apps on cloud.gov.

## Scope

- Broker apps: `csb-aws`, `csb-gcp`, `csb-azure`
- Broker registrations: `csb-aws-sandbox`, `csb-gcp-sandbox`, `csb-azure-sandbox`
- Shared state database: `csb-sql`

## Prerequisites

- CLI tools installed: `cf`, `pnpm`, `git`
- Logged in and targeted to the correct org/space:

```bash
cf login -a api.fr.cloud.gov --sso
cf target
```

- Env files present and populated:
  - `scripts/envs/aws.env`
  - `scripts/envs/gcp.env`
  - `scripts/envs/azure.env`

For credential bootstrapping details, use `docs/credential-provisioning.md`.

## Standard Health Check

```bash
pnpm run broker:status
```

Expected:

- App(s) are `started` when actively serving provisions
- Service broker registration exists in `cf service-brokers`
- Marketplace includes expected `csb-*` offerings

## Deploy or Redeploy

### 1) Ensure submodules are current

```bash
pnpm run submodule:init
pnpm run submodule:status
```

### 2) Ensure broker DB exists

```bash
pnpm run broker:db
```

### 3) Deploy provider brokers

```bash
pnpm run broker:deploy:aws
pnpm run broker:deploy:gcp
pnpm run broker:deploy:azure
```

Or deploy all:

```bash
pnpm run broker:deploy:all
```

### 4) Validate post-deploy state

```bash
pnpm run broker:status
cf service-brokers
cf marketplace
```

## Start/Stop Operations

Use these to reduce runtime resource usage when no provisioning activity is needed.

```bash
pnpm run broker:start:aws
pnpm run broker:start:gcp
pnpm run broker:start:azure

pnpm run broker:stop:aws
pnpm run broker:stop:gcp
pnpm run broker:stop:azure
```

Batch operations:

```bash
pnpm run broker:start:all
pnpm run broker:stop:all
```

## Functional Smoke Tests

After deploy, run a quick provision/deprovision check per provider.

```bash
cf create-service csb-aws-postgresql sandbox-8h smoke-aws-pg -c '{"project":"ops-smoke","owner":"owner@example.gov"}'
cf services
cf delete-service smoke-aws-pg -f
```

Use equivalent GCP/Azure service offerings when those brokers are enabled.

## Rollback Procedure

Use this when a broker deploy is unhealthy or provisioning regresses.

1. Identify last known good commit in this repo and relevant submodule pointer(s).
2. Check out that commit locally.
3. Re-run provider deploy script(s) for affected broker(s).
4. Re-run smoke tests.

Operator notes:

- Rollback is implemented as a redeploy of previous code/submodule pointers.
- Keep `csb-sql` intact during rollback to preserve broker state.

## Secrets Rotation

When rotating AWS keys, GCP service account JSON, or Azure service principal secret:

1. Update local env file (`scripts/envs/*.env`).
2. Redeploy affected broker (`pnpm run broker:deploy:<provider>`).
3. Verify app health and broker registration.
4. Perform one smoke provision/deprovision.

Reference: `docs/credential-provisioning.md`.

## Planned Teardown (Broker App + Registration)

Use only when intentionally retiring a broker from a space.

```bash
pnpm run broker:teardown:aws
pnpm run broker:teardown:gcp
pnpm run broker:teardown:azure
```

Important:

- Deprovision dependent service instances first.
- Teardown does not remove `csb-sql` automatically.

## Escalation Triggers

Escalate to platform operators when any of the following occurs:

- Broker app crash loops after redeploy
- `cf marketplace` missing expected offerings after successful push
- Service provision operations fail across multiple offerings/providers
- Shared `csb-sql` instability impacts more than one broker
