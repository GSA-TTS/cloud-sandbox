---
name: cloud-foundry-broker-operations
description: "Use when: operating, starting, stopping, restarting, checking, or troubleshooting Cloud Foundry service brokers in the cloud-sandbox project; cloud.gov CF target, broker registration, marketplace offerings, and safe broker lifecycle operations."
argument-hint: "Describe the broker operation or health issue"
---

# Cloud Foundry Broker Operations

Operate the deployed Cloud Service Broker applications safely in cloud.gov. This
skill is for routine lifecycle operations only; it is not a deployment or
teardown workflow.

## Verified Environment

- API endpoint: `https://api.fr.cloud.gov`
- Organization: `gsa-tts-iae-lava-beds`
- Normal operations space: `dev`
- Broker app / registration pairs:

  | App | Registration |
  | --- | --- |
  | `csb-aws` | `csb-aws-sandbox` |
  | `csb-gcp` | `csb-gcp-sandbox` |
  | `csb-azure` | `csb-azure-sandbox` |

The registrations and marketplace catalog persist when an app is stopped. A
normal start brings the OSBAPI endpoint back without rebuilding, pushing, or
re-registering the broker.

## Procedure

1. Authenticate and confirm the intended context:

   ```bash
   cf login -a api.fr.cloud.gov --sso
   cf target -o gsa-tts-iae-lava-beds -s dev
   cf target
   ```

2. Inspect before changing anything:

   ```bash
   pnpm run broker:status
   ```

   Confirm the named app exists and its registration appears in
   `cf service-brokers`. Do not infer a broker is undeployed merely because its
   app is stopped.

3. For a stopped broker, prefer starting it:

   ```bash
   pnpm run broker:start:aws
   pnpm run broker:start:gcp
   pnpm run broker:start:azure
   ```

4. Only use the provider-specific restart scripts if the app is already running
   and requires a deliberate stop/start recovery. This causes a short OSBAPI
   outage:

   ```bash
   pnpm run broker:restart:aws
   pnpm run broker:restart:gcp
   ```

5. Validate after every lifecycle operation:

   ```bash
   cf app csb-aws
   cf app csb-gcp
   cf app csb-azure
   cf service-brokers
   cf marketplace
   ```

   An application is healthy when its requested state is `started`, its web
   instance is `running` and `ready`, its registration remains listed, and the
   expected `csb-*` offerings are in the marketplace.

## Guardrails

- Use `broker:start:<provider>` for normal recovery; it avoids an unnecessary
  OSBAPI outage.
- Do **not** use `broker:deploy:*` as a restart. Deploy rebuilds/pushes broker
  code, injects provider credentials, and updates the registration.
- Do **not** use `broker:teardown:*` for recovery. It deregisters the broker and
  deletes its app.
- Preserve the shared `csb-sql` backing database.
- Do not expose, alter, or commit `scripts/envs/*.env` during routine lifecycle
  operations.
- Do not provision or deprovision a smoke-test instance without explicit
  authorization; those actions create or destroy cloud resources.

## Related Material

- [Operations runbook](../../../docs/operations-runbook.md)
- [Credential provisioning](../../../docs/credential-provisioning.md)
- [Cloud Service Brokers agent](../../agents/cloud-service-brokers.md)