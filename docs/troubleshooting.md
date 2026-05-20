# Cloud Sandbox Troubleshooting Guide

Use this guide to diagnose and fix common broker deployment and provisioning issues.

## Quick Triage Commands

```bash
cf target
pnpm run broker:status
cf apps
cf service-brokers
cf marketplace
```

These commands usually identify whether the problem is auth, app health, broker registration, or catalog visibility.

## Common Issues

### Not logged in to Cloud Foundry

Symptoms:

- Scripts fail with `ERROR: Not logged in to CF`

Fix:

```bash
cf login -a api.fr.cloud.gov --sso
cf target
```

### Missing env file for deploy scripts

Symptoms:

- `Environment file not found: scripts/envs/<provider>.env`

Fix:

```bash
cp scripts/envs/aws.env.example scripts/envs/aws.env
cp scripts/envs/gcp.env.example scripts/envs/gcp.env
cp scripts/envs/azure.env.example scripts/envs/azure.env
```

Then populate real values. See `docs/credential-provisioning.md`.

### Submodule not initialized

Symptoms:

- `ERROR: Submodule not initialised`

Fix:

```bash
pnpm run submodule:init
pnpm run submodule:status
```

### Broker app missing from marketplace

Symptoms:

- App exists in `cf apps`, but expected offerings do not appear in `cf marketplace`

Checks:

```bash
cf service-brokers
cf marketplace
```

Fix path:

1. Confirm broker registration exists (for example `csb-aws-sandbox`).
2. If registration is missing, redeploy with `pnpm run broker:deploy:<provider>`.
3. Re-run `cf marketplace`.

### `csb-sql` backing database errors

Symptoms:

- Broker startup/provision errors referencing DB connectivity/state

Checks:

```bash
cf service csb-sql
```

Fix path:

1. If missing, create it: `pnpm run broker:db`.
2. If failed, follow service status output and recreate if required.
3. Redeploy affected brokers.

### Azure deploy fails with placeholder credentials

Symptoms:

- `deploy-azure.sh` exits on placeholder values (`CHANGEME`, `xxxxxxxx-...`)

Fix:

- Replace placeholders in `scripts/envs/azure.env` with real values for:
  - `SECURITY_USER_PASSWORD`
  - `ARM_TENANT_ID`
  - `ARM_SUBSCRIPTION_ID`
  - `ARM_CLIENT_ID`
  - `ARM_CLIENT_SECRET`

### Azure OpenAI preflight failure

Symptoms:

- Errors during Azure preflight before broker push

Checks:

```bash
az account show
pnpm run azure:openai:preflight
```

Fix path:

1. Ensure `az` is installed and authenticated.
2. Confirm subscription is set to `ARM_SUBSCRIPTION_ID`.
3. Verify preflight env values in `scripts/envs/azure.env`.

### GCP deploy fails on auth or missing project

Symptoms:

- `GOOGLE_CREDENTIALS is not set`
- `GOOGLE_PROJECT is not set`

Fix:

- Update `scripts/envs/gcp.env` with valid `GOOGLE_CREDENTIALS` JSON and `GOOGLE_PROJECT`.
- Re-run `pnpm run broker:deploy:gcp`.

### Service provision fails after broker redeploy

Symptoms:

- `cf create-service ...` returns broker/provision errors

Checks:

```bash
cf services
cf service <instance-name>
cf logs <broker-app-name> --recent
```

Fix path:

1. Confirm broker app is started.
2. Confirm broker is registered.
3. Confirm env vars are valid and redeploy.
4. Retry with a known-good offering and `sandbox-8h` plan.

## Safe Recovery Sequence

When root cause is unclear, use this sequence:

1. `cf login -a api.fr.cloud.gov --sso`
2. `pnpm run submodule:init`
3. `pnpm run broker:db`
4. Redeploy affected provider(s): `pnpm run broker:deploy:<provider>`
5. `pnpm run broker:status`
6. Run one smoke provision/deprovision

## When to Escalate

Escalate when:

- Multiple brokers fail at once
- `csb-sql` is degraded and blocks all providers
- Marketplace remains empty after confirmed successful deploy
- Repeated provisioning failures persist after full redeploy and auth refresh
