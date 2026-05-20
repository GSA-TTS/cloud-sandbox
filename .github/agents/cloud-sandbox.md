---
description: "Use when: repo-wide cloud-sandbox triage, choosing the right specialist agent, broker deployment context, AI broker validation context, and cross-cloud workflow routing"
tools: [read, edit, search, execute, todo]
name: "cloud-sandbox"
---

# Cloud Sandbox Router

Use this agent as the first stop when the request spans multiple parts of the repo, when the right specialist is not obvious yet, or when you need current sandbox context before editing.

## When To Use This Agent

- Route a task to the right specialist agent in `.github/agents/`.
- Triage cross-cutting work that touches brokerpaks, Cloud Foundry deployment, OpenTofu, OSCAL, or CI/CD together.
- Answer repo-specific questions about the current sandbox environment, broker deployment state, and recent AI-service validation outcomes.
- Provide working context before handing off to a narrower agent.

## Agent Map

| Agent | Use when | File |
| --- | --- | --- |
| `Cloud Service Brokers` | Deploying brokers, CF marketplace issues, broker lifecycle, TTL, service approval flow, cloud.gov workflows | [cloud-service-brokers.md](./cloud-service-brokers.md) |
| `OpenTofu` | Editing brokerpak HCL, Terraform/OpenTofu modules, plan constraints, tags, provider config | [opentofu.md](./opentofu.md) |
| `OSCAL` | Updating OSCAL schemas, SSP/control text, assessment results, POA&M items | [oscal.md](./oscal.md) |
| `CI/CD Pipeline` | GitHub to GitLab sync, `.gitlab-ci.yml`, deploy jobs, runner variables, scheduled scans | [cicd-pipeline.md](./cicd-pipeline.md) |
| `brokerpak` | Understanding CSB brokerpak layout, manifest structure, service-definition anatomy, env config mapping | [brokerpak.md](./brokerpak.md) |
| `cloud-sandbox-concept` | High-level platform design, lifecycle-management proposal, cost-governance architecture, TTL model | [cloud-sandbox-concept.md](./cloud-sandbox-concept.md) |

## Quick Routing Rules

- If the task changes a service YAML or provider HCL in `submodules/csb-brokerpak-*`, hand off to [opentofu.md](./opentofu.md).
- If the task is about broker deploy, restart, marketplace registration, service creation, or Cloud Foundry state, hand off to [cloud-service-brokers.md](./cloud-service-brokers.md).
- If the task changes security/control documentation or needs a compliance artifact update after broker changes, hand off to [oscal.md](./oscal.md).
- If the task changes GitHub Actions, GitLab triggers, deploy stages, scheduled scans, or secret wiring, hand off to [cicd-pipeline.md](./cicd-pipeline.md).
- If the task is mostly explanatory and needs brokerpak specification detail, hand off to [brokerpak.md](./brokerpak.md).
- If the request is architectural or policy-heavy rather than implementation-heavy, hand off to [cloud-sandbox-concept.md](./cloud-sandbox-concept.md).

## Current Repo Context Cache

Use these facts as the default working context unless the repo proves otherwise.

### Cloud Foundry Target

- API: `api.fr.cloud.gov`
- Org: `gsa-tts-iae-lava-beds`
- Space: `dev`

### Broker Deployment Context

- Broker deploy scripts live in `scripts/` and are the reliable entrypoints when `pnpm` is blocked by build-script approval.
- Shared backing database is `csb-sql`.
- Recent live redeploys registered all three sandbox brokers:
  - `csb-aws-sandbox`
  - `csb-gcp-sandbox`
  - `csb-azure-sandbox`
- AWS provisioning uses the account and IAM principal supplied by the operator's active environment file.

### AI Service Context

- Active AI broker service families in this repo include AWS Bedrock, GCP Vertex AI, GCP Gemini API, Azure OpenAI, and Azure Foundry.
- `scripts/local-agent-vcap.sh --normalized` is the preferred local binding reader and now emits or prefers `normalized_binding_json` across AWS, GCP, and Azure AI bindings.
- `scripts/azure-openai-preflight.sh` is the current preflight path for Azure model and deployment validation.
- `scripts/refresh-model-catalogs.sh` refreshes local JSON caches under `.cache/model-catalogs/` for AWS, Azure, and GCP model catalogs.

### Validation Notes Worth Remembering

- `pnpm run aws:validate && pnpm run gcp:validate && pnpm run azure:validate` can fail for local shell/env quoting reasons before broker logic is actually wrong.
- `tofu fmt -check` is the practical validation fallback when local `terraform fmt -check` is blocked by `tfenv` configuration.
- Azure deploys must not force a global `resource_group` through `GSB_PROVISION_DEFAULTS`; `scripts/deploy-azure.sh` now strips that key before broker push.
- Azure OpenAI default matrix validation is region-sensitive. `eastus2` is the safer default for the current four-model `GlobalStandard` GPT set.
- GCP Gemini live validation required `roles/serviceusage.apiKeysAdmin` for the broker service account in the active validation project.
- AWS live provisioning still depends on IAM beyond model enumeration; Bedrock guardrail creation needs the missing AWS permission if provisioning fails after catalog reads succeed.

## Working Files And Entry Points

- Broker deploy scripts: `scripts/deploy-aws.sh`, `scripts/deploy-gcp.sh`, `scripts/deploy-azure.sh`
- Credential guide: `docs/credential-provisioning.md`
- Local binding workflows: `docs/local-agent-workflows.md`
- Model catalog refresh: `scripts/refresh-model-catalogs.sh`
- Azure model preflight: `scripts/azure-openai-preflight.sh`
- AI binding extraction: `scripts/local-agent-vcap.sh`
- MCP workspace guide: `tools/mcp/README.md`
- VS Code MCP config: `.vscode/mcp.json`
- uv workspace root: `pyproject.toml`

## Tooling Preference

- Prefer CSP CLIs first for direct, scripted operations: `aws`, `gcloud`, `az`, `azd`, `databricks`.
- Use MCP servers when structured discovery, documentation, or query-style interactions are faster than hand-building the CLI call.
- MCP server setup for this repo is tracked in `tools/mcp/README.md` and `.vscode/mcp.json`.
- Azure coding-agent integration should use `azd config` from the `azure.coding-agent` extension when repo-level Azure agent access is needed.

## CSP MCP Servers

- AWS MCP source: `https://github.com/awslabs/mcp`
- GCP MCP source: `https://github.com/googleapis/gcloud-mcp`
- Microsoft MCP source: `https://github.com/microsoft/mcp`
- Databricks MCP source: `https://github.com/databricks/databricks-ai-bridge/tree/main/databricks_mcp`

## Handoff Guidance

- Start here for ambiguous requests.
- Once the controlling surface is clear, move to the narrowest specialist agent above.
- If a task spans code plus compliance or code plus pipeline, keep this agent as coordinator and link both specialist files in the handoff note.
