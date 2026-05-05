# Local Agent Workflows

This document covers the local developer workflow for requesting brokered AI
credentials from Cloud Foundry and wiring them into the three client surfaces we
support today:

1. Zed
2. CLI agents
3. VS Code

The workflow starts the same way for every client:

1. Target the cloud.gov org and space that hosts the brokers.
2. Create a brokered AI service instance.
3. Bind that service to a scratch CF app.
4. Extract the binding credentials from `VCAP_SERVICES`.
5. Prefer the normalized binding payload, then map provider-specific values only when needed.

## Prerequisites

- `cf` CLI installed and logged into cloud.gov
- Access to `gsa-tts-iae-lava-beds / dev`
- The AI brokers already deployed:
  - `csb-aws-sandbox`
  - `csb-gcp-sandbox`
  - `csb-azure-sandbox`

Target the sandbox space first:

```bash
cf target -o gsa-tts-iae-lava-beds -s dev
```

## Supported Services

| Provider | Marketplace service | Primary local use |
| --- | --- | --- |
| AWS | `csb-aws-bedrock` | Bedrock-backed Anthropic / Titan access |
| GCP | `csb-google-gemini` | Gemini API key access |
| GCP | `csb-google-vertex-ai` | Gemini / Vertex AI access |
| Azure | `csb-azure-openai` | OpenAI-compatible endpoint for local tools |
| Azure | `csb-azure-foundry` | Preview Foundry-aligned per-model Azure OpenAI access |

## Step 1: Create a Service Instance

All three services can now rely on broker-side Cloud Foundry provenance for org,
space, and user attribution. Add provider-specific overrides only when you need
to change the default model or region behavior for a given service. Those model
override fields are supported on `sandbox-8h` as well as `standard`; they are
not unique to the standard plans.

### AWS Bedrock

```bash
cf create-service csb-aws-bedrock sandbox-8h local-bedrock \
  -c '{"models":"[\"anthropic.claude-3-haiku-20240307-v1:0\",\"amazon.titan-embed-text-v1\"]"}'
```

AWS Bedrock also exposes fixed single-model plans. These are simpler than the
Azure OpenAI plans because Bedrock does not create named deployments; each plan
just pins the IAM allowlist for `bedrock:InvokeModel` to a specific model ID.

Current fixed plans:

- `claude-opus-4-6`
- `claude-opus-4-5`
- `claude-sonnet-4-6`
- `claude-sonnet-4-5`
- `claude-haiku-4-5`
- `llama-4-maverick-17b-instruct`
- `llama-4-scout-17b-instruct`
- `llama-3-3-70b-instruct`
- `gpt-oss-120b`
- `gemma-3-12b-it`

And `standard` now enables the full requested model set by default.

### GCP Vertex AI

```bash
cf create-service csb-google-vertex-ai sandbox-8h local-vertex \
  -c '{"models":"[\"gemini-1.5-flash-001\",\"text-embedding-004\"]"}'
```

### GCP Gemini API

```bash
cf create-service csb-google-gemini sandbox-8h local-gemini
```

### Azure OpenAI

```bash
cf create-service csb-azure-openai sandbox-8h local-openai
```

The Azure OpenAI catalog now defaults both `sandbox-8h` and `standard` to the
full requested GPT deployment set: `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`,
`gpt-5.3-codex`, and `gpt-5.2`. `gpt-5.5` is the first deployment in the
default payload and should be treated as the default chat target for local
OpenAI-compatible clients. Override `deployments_json` only when the target
subscription or region cannot support the full matrix.

### Azure Foundry Preview

```bash
cf create-service csb-azure-foundry sandbox-8h local-foundry \
  -c '{"foundry_hub_name":"sandbox-hub","foundry_project_name":"sandbox-project","deployment_name":"text-embedding-3-small","model_name":"text-embedding-3-small","model_version":"1","model_capacity":10}'
```

This service is a transitional preview of the `azure_foundry_identity` family.
It currently provisions a backing Azure OpenAI resource with a single model
deployment and returns the OpenAI key, endpoint, API version, deployment
metadata, and Foundry hub/project metadata. It does not yet return a true
Foundry RBAC-backed token or client secret.

Poll until the instance is ready:

```bash
cf service local-openai
cf service local-foundry
cf service local-gemini
cf service local-vertex
cf service local-bedrock
```

## Step 2: Bind to a Scratch App and Read `VCAP_SERVICES`

The broker returns credentials through the OSB bind response, so the easiest
way to inspect them is to bind the service to a scratch app you control and read
that app's environment.

If you already have a scratch app in the space, reuse it. Then bind the service:

```bash
bash scripts/local-agent-vcap.sh scratch-app local-openai
```

If you want to select a specific `VCAP_SERVICES` label explicitly, pass it as
the third argument:

```bash
bash scripts/local-agent-vcap.sh scratch-app local-openai csb-azure-openai
```

The helper checks the app's current `/v3/apps/<guid>/env` payload first and
only falls back to `cf restart` if the new binding is not visible yet.

The binding payload will appear under `VCAP_SERVICES` for the relevant service
name. Current AI bindings now include the effective instance metadata and the
final resource tags or labels JSON returned by the broker, plus Cloud Foundry
provenance JSON for org, space, user, and bound app context.

To print only the normalized runtime contract, use:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app local-openai
```

The helper prefers `credentials.normalized_binding_json` when present. For older
bindings, it synthesizes the same shape from the provider-specific credential
fields so the local workflow can migrate without waiting for every instance to
be rebound.

## VCAP Contract

### Normalized binding payload

The normalized payload is the preferred contract for local tooling and future
app-side adapters. It has the following top-level shape:

- `version`
- `provider`
- `provisioner_family`
- `connection_type`
- `endpoint`
- `access`
- `grant`
- `credential`

Provider-specific fields remain in `VCAP_SERVICES` for compatibility and are
documented below.

### AWS Bedrock binding credentials

`VCAP_SERVICES["csb-aws-bedrock"][0].credentials` includes:

- `access_key_id`
- `secret_access_key`
- `region`
- `models`
- `bedrock_endpoint`
- `guardrail_id`
- `budget_amount`
- `budget_enforcement_mode`
- `ttl_expires_at`
- `instance_name`
- `binding_provenance_json`
- `resource_tags_json`

### GCP Vertex AI binding credentials

`VCAP_SERVICES["csb-google-vertex-ai"][0].credentials` includes:

- `credentials_json`
- `project_id`
- `region`
- `api_endpoint`
- `models`
- `bucket_name`
- `budget_amount`
- `budget_enforcement_mode`
- `ttl_expires_at`
- `instance_name`
- `binding_provenance_json`
- `resource_labels_json`

### GCP Gemini API binding credentials

`VCAP_SERVICES["csb-google-gemini"][0].credentials` includes:

- `api_key`
- `project_id`
- `api_endpoint`
- `models`
- `budget_enforcement_mode`
- `ttl_expires_at`
- `instance_name`
- `binding_provenance_json`
- `resource_labels_json`
- `normalized_binding_json`

### Azure OpenAI binding credentials

`VCAP_SERVICES["csb-azure-openai"][0].credentials` includes:

- `endpoint`
- `api_key`
- `api_version`
- `deployments`
- `ttl_expires_at`
- `budget_amount`
- `budget_enforcement_mode`
- `instance_name`
- `binding_provenance_json`
- `resource_tags_json`

### Azure Foundry preview binding credentials

`VCAP_SERVICES["csb-azure-foundry"][0].credentials` includes:

- `endpoint`
- `api_key`
- `api_version`
- `deployments`
- `implementation_state`
- `resource_tags_json`
- `foundry_hub_name`
- `foundry_project_name`
- `deployment_name`
- `model_name`
- `model_version`
- `model_capacity`
- `resource_group`
- `location`
- `azure_tenant_id`
- `azure_subscription_id`
- `budget_enforcement_mode`
- `token_audience`
- `ttl_expires_at`
- `binding_provenance_json`
- `normalized_binding_json`

This preview binding now includes a usable Azure OpenAI key and a single-model
deployment contract, but it is still transitional rather than a true Foundry
RBAC-backed identity flow.

## Option 1: Zed

Zed already has first-party provider configuration for the three provider types
we care about here.

- OpenAI-compatible provider docs: [Zed OpenAI provider](https://zed.dev/docs/ai/llm-providers#openai)
- Google AI docs: [Zed Google AI provider](https://zed.dev/docs/ai/llm-providers#google-ai)
- Amazon Bedrock docs: [Zed Amazon Bedrock provider](https://zed.dev/docs/ai/llm-providers#amazon-bedrock)

### Zed with Azure OpenAI

Use the Azure binding's `endpoint`, `api_key`, and `api_version` as the Zed
OpenAI-compatible provider values.

Map these values:

- Base URL: `endpoint`
- API key: `api_key`
- API version: `api_version`
- Model name: choose one of the deployment names from `deployments`

### Zed with GCP Vertex AI / Gemini

Use the Vertex binding's `credentials_json`, `project_id`, and `region`.

Map these values:

- Project: `project_id`
- Region: `region`
- Credentials: `credentials_json`
- Model list: `models`

### Zed with AWS Bedrock

Use the Bedrock binding's `access_key_id`, `secret_access_key`, `region`, and
`bedrock_endpoint`.

Map these values:

- Access key ID: `access_key_id`
- Secret access key: `secret_access_key`
- Region: `region`
- Runtime endpoint: `bedrock_endpoint`
- Allowed models: `models`

## Option 2: CLI Agents

### Codex CLI

Codex CLI is the cleanest fit for the Azure OpenAI service because the broker
returns an OpenAI-compatible endpoint and API key.

Install or update Codex CLI:

```bash
npm install -g @openai/codex@latest
```

Create or edit `~/.codex/config.toml`:

```toml
profile = "default"

[profiles.default]
model_provider = "azure-openai"

[model_providers.azure-openai]
name = "Cloud Sandbox Azure OpenAI"
base_url = "https://<endpoint-from-vcap>/openai"
query_params = { api-version = "2025-04-01-preview" }
wire_api = "responses"
env_key = "AZURE_OPENAI_API_KEY"
```

Export the bound credential locally before starting Codex:

```bash
export AZURE_OPENAI_API_KEY='<api_key-from-vcap>'
codex
```

Important details:

- `base_url` must end with `/openai`. Using the raw account endpoint such as
  `https://<name>.openai.azure.com/` causes `404 Resource not found` when Codex
  calls `/responses`.
- `env_key` is the name of the environment variable, not the secret value.
  For example, use `env_key = "AZURE_OPENAI_API_KEY"`, then export the actual
  key into that variable.
- Use `/model` inside Codex to pick one of the deployment names from
  `deployments`, for example `gpt-5.4-mini`.
- The current sandbox deployment set is intentionally small. A typical binding
  returns `gpt-5.4-mini` and `text-embedding-3-small`. If you need a different
  deployment, create the matching fixed plan or use the `standard` plan.
- If Codex reports `404 DeploymentNotFound`, the endpoint is usually correct and
  the selected model is wrong. Switch the active model to a deployed Azure
  deployment name, typically `gpt-5.4-mini` for sandbox chat.

### Gemini CLI

Gemini CLI fits the Vertex AI service. Install the current CLI:

```bash
npm install -g @google/gemini-cli
```

Write the service account JSON from `credentials_json` to a local file and point
Gemini CLI at it:

```bash
mkdir -p ~/.gemini
printf '%s' "$VERTEX_CREDENTIALS_JSON" > ~/.gemini/vertex-service-account.json
chmod 600 ~/.gemini/vertex-service-account.json
```

Then create `~/.gemini/.env`:

```bash
GEMINI_MODEL=gemini-2.5-pro
GOOGLE_CLOUD_PROJECT=<project_id-from-vcap>
GOOGLE_CLOUD_LOCATION=<region-from-vcap>
GOOGLE_APPLICATION_CREDENTIALS=$HOME/.gemini/vertex-service-account.json
```

Start Gemini CLI:

```bash
gemini
```

Important details:

- If `gemini` is not found after a global npm install, add npm's global bin
  directory to your shell path:

```bash
export PATH="$(npm config get prefix)/bin:$PATH"
```

- The brokered Vertex credentials are valid for Application Default Credentials.
  If you can run `gcloud auth application-default print-access-token` with
  `GOOGLE_APPLICATION_CREDENTIALS` pointing at the file above, auth is working.
- `gemini-2.5-pro` was validated against the current sandbox project and region.
  If the CLI defaults to a preview model you do not have access to, explicitly
  set `GEMINI_MODEL` before launching the CLI.

### Claude Code

Claude Code does not map cleanly to the raw broker bindings in this repo today.
The current brokered services expose:

- Bedrock credentials for Bedrock's native API
- Vertex AI credentials for Vertex / Gemini
- Azure OpenAI credentials for OpenAI-compatible APIs

Claude Code expects an Anthropic-compatible base URL or gateway. That means the
supported local path today is:

- use Zed if you want Bedrock-hosted Claude models directly
- use a separate gateway if you need Claude Code specifically

This is a current platform gap, not a local setup mistake.

## Option 3: VS Code

VS Code is supported through OpenAI-compatible extensions and provider-specific
extensions that can consume the same binding values.

### VS Code with Azure OpenAI

Use the Azure binding values in the extension of your choice:

- Endpoint: `endpoint`
- Key: `api_key`
- API version: `api_version`
- Model or deployment: values from `deployments`

### VS Code with Vertex AI

Use:

- `credentials_json`
- `project_id`
- `region`
- `models`

### VS Code with Bedrock

Use:

- `access_key_id`
- `secret_access_key`
- `region`
- `bedrock_endpoint`
- `models`

## Tagging and Provenance

Current state:

- AI resources receive broker-side tags or labels derived from `request.default_labels`
  plus the provider-specific common metadata such as `TTLExpiry`, `ManagedBy`,
  and `Environment`.
- Those effective tags or labels are now also returned to binding consumers as
  `resource_tags_json` or `resource_labels_json`, so the PaaS-side app can see
  the same metadata contract expected on the IaaS-side resources.

Current gap:

- This repo does not yet prove that per-request `user` identity and bound `app`
  identity are exposed to the brokerpak templates for these services.
- `organization`, `space`, `project`, and `owner` are part of the intended
  provenance model, but only the fields already carried by CSB default labels and
  explicit request payloads are guaranteed today.

Until that gap is closed, every local provision request should include at least:

```json
{
  "project": "sandbox-local-dev",
  "owner": "you@gsa.gov"
}
```

That keeps the Cloud Foundry request and the cloud-provider tags aligned enough
for cost and lifecycle investigations.
