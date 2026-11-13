# MCP Workspace

This workspace adds cloud-provider MCP servers alongside the existing CLI-first workflows in this repo.

## Preference Order

Use the provider CLI first when the command is direct and auditable:

- AWS: `aws`
- GCP: `gcloud`
- Azure: `az`, `azd`
- Databricks: `databricks`

Use the MCP server when it is faster for discovery, structured queries, documentation lookups, or multi-step cloud navigation from an MCP-capable client.

## Workspace Files

- Root uv workspace: `pyproject.toml`
- MCP helper project: `tools/mcp/pyproject.toml`
- VS Code MCP config: `.vscode/mcp.json`

## Provider MCP Servers

| Provider | Source | Workspace config | Auth model | Notes |
| --- | --- | --- | --- | --- |
| AWS | [AWS MCP Server](https://docs.aws.amazon.com/aws-mcp/latest/userguide/what-is-mcp-server.html) | `aws-api` | local AWS credential chain | Configured with a pinned `mcp-proxy-for-aws` connection to the AWS-managed MCP endpoint |
| GCP | [googleapis/gcloud-mcp](https://github.com/googleapis/gcloud-mcp) | `gcloud` | active `gcloud` account | Configured with `npx -y @google-cloud/gcloud-mcp` |
| Azure | [microsoft/mcp](https://github.com/microsoft/mcp) | `azure-resource-manager` | Azure signed-in browser/session auth against ARM MCP | Configured as remote HTTP MCP at `https://mcp.management.azure.com` |
| Databricks | [databricks/databricks-ai-bridge](https://github.com/databricks/databricks-ai-bridge/tree/main/databricks_mcp) | `databricks` | Databricks CLI auth | Configured with `uvx databricks-mcp` |

## Setup

### 1. Sync the uv workspace

```bash
uv sync --package cloud-sandbox-mcp-tools
```

This installs the Python-side helper dependencies used here, including `databricks-mcp`.

### 2. Verify local CLIs

```bash
uv --version
node --version
npm --version
aws --version
gcloud version
az version
azd version
databricks -v
```

### 3. Authenticate each provider

AWS:

```bash
set -a
source scripts/envs/aws.env
set +a
aws sts get-caller-identity
```

GCP:

```bash
set -a
source scripts/envs/gcp.env
set +a
gcloud config set project "$GOOGLE_PROJECT"
```

Azure:

```bash
az login --use-device-code
az account set --subscription "$ARM_SUBSCRIPTION_ID"
```

Databricks:

```bash
databricks auth login
```

## VS Code MCP Hosts

The workspace MCP server definitions live in `.vscode/mcp.json`.

After opening the repo in VS Code, reload the window if the new MCP entries do not appear immediately.

## Azure Coding Agent Setup

`azd` is the supported repo-level setup path for Azure MCP in a coding-agent workflow.

The local machine now has the `azure.coding-agent` azd extension installed, which exposes:

```bash
azd config --help
```

To wire the GitHub repo for Azure access in a coding-agent flow, run:

```bash
azd config --remote-name GSA-TTS/cloud-sandbox
```

That command is intentionally kept separate from the local `.vscode/mcp.json` setup because it can create repo automation and Azure access configuration tied to GitHub.

## Provider-Specific Notes

### AWS

- The workspace uses AWS's managed MCP server through `uvx mcp-proxy-for-aws@1.6.3 https://aws-mcp.us-east-1.api.aws/mcp --metadata AWS_REGION=us-east-1`.
- The previous aggregate `awslabs.core-mcp-server` package is yanked. The interim `awslabs.aws-api-mcp-server` replacement is also entering end of development; use the managed server instead.
- Authenticate through the approved local AWS credential source (for example, GSA SSO or a configured profile) before starting the proxy. The configuration intentionally does not store credentials.

### GCP

- `gcloud-mcp` uses the permissions of the active `gcloud` account.
- Prefer service-account or impersonated auth for least privilege when using MCP beyond local exploration.

### Azure

- The workspace uses the Azure Resource Manager remote MCP endpoint for general Azure resource queries.
- Continue using `az` and `azd` first for deterministic scripting, deployment, and subscription management.

### Databricks

- `databricks-mcp` comes from the `databricks_mcp` package in `databricks-ai-bridge`.
- It relies on Databricks CLI auth and is useful when the client benefits from structured workspace or serving interactions.
