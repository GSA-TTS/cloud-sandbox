# Cloud Sandbox Documentation Index

This directory contains implementation, operations, and compliance documentation for the Cloud Sandbox platform.

## Start Here

- Platform overview: `README.md`
- Credential setup: `docs/credential-provisioning.md`
- Local workflows for bound service credentials: `docs/local-agent-workflows.md`
- Daily operations: `docs/operations-runbook.md`
- Failure handling: `docs/troubleshooting.md`

## By Audience

- Engineers provisioning services:
  - `docs/credential-provisioning.md`
  - `docs/service-instance-credential-commands.md`
  - `docs/vscode-auth-configuration.md`
  - `docs/zed-auth-configuration.md`
  - `docs/opencode-auth-configuration.md`
- Broker operators:
  - `docs/operations-runbook.md`
  - `docs/troubleshooting.md`
  - `docs/open-questions.md`
- Compliance and architecture reviewers:
  - `docs/architecture-diagrams.md`
  - `docs/service-approval-extraction-summary.md`
  - `docs/aws/service-approval-review.md`
  - `docs/azure/service-approval-review.md`
  - `docs/gcp/service-approval-review.md`
  - `docs/adr/0001-ai-access-families.md`

## Current Status Notes

- Several policy and implementation decisions are intentionally tracked as open items in `docs/open-questions.md`.
- Some AWS approval documents still reference legacy source filenames that are not present in this repo.
- `docs/feature-requests.md` tracks medium-term improvements discovered during codebase review.

## Suggested Reading Paths

- New engineer path:
  1. `README.md`
  2. `docs/credential-provisioning.md`
  3. `docs/local-agent-workflows.md`
  4. `docs/service-instance-credential-commands.md`
- New operator path:
  1. `README.md`
  2. `docs/operations-runbook.md`
  3. `docs/troubleshooting.md`
  4. `docs/open-questions.md`
- Security/compliance path:
  1. `docs/architecture-diagrams.md`
  2. `docs/service-approval-extraction-summary.md`
  3. `docs/open-questions.md`
