# VS Code Auth Configuration

This guide maps the brokered `VCAP_SERVICES` bindings into VS Code-compatible
provider settings. For the shared provisioning and binding flow, see
`docs/local-agent-workflows.md`.

## Prerequisites

- `cf` logged into `gsa-tts-iae-lava-beds / dev`
- A scratch app such as `scratch-app`
- A VS Code extension that supports the target provider or OpenAI-compatible
  configuration

## Recommended validated instances

- AWS Bedrock: `verify-bedrock-0505`
- GCP Vertex AI: `verify-vertex-0505`
- GCP Gemini API: `verify-gemini-0505b`
- Azure OpenAI: `verify-openai-eastus2-0511095227`
- Azure Foundry preview: `verify-foundry-0505c`

## Azure OpenAI

Use an extension that accepts an OpenAI-compatible endpoint.

Extract the values:

```bash
AZURE_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-openai-eastus2-0511095227)
printf '%s' "$AZURE_JSON" | jq -r '.credentials.endpoint'
printf '%s' "$AZURE_JSON" | jq -r '.credentials.api_key'
printf '%s' "$AZURE_JSON" | jq -r '.credentials.api_version'
printf '%s' "$AZURE_JSON" | jq -r '.credentials.deployments'
```

Map them as:

- Endpoint: `endpoint`
- Key: `api_key`
- API version: `api_version`
- Model or deployment: values from `deployments`

Use a chat deployment such as `gpt-5-4-mini`, `gpt-5-4`, or `gpt-5-5`.

## GCP Vertex AI

Use a provider-specific extension that accepts Vertex service account auth.

Extract the values:

```bash
VERTEX_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-vertex-0505)
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.credentials_json'
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.project_id'
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.region'
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.models'
```

Map them as:

- `credentials_json`
- `project_id`
- `region`
- `models`

## GCP Gemini API

If your chosen extension supports Gemini API key auth directly, use the Gemini
binding values:

```bash
GEMINI_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-gemini-0505b)
printf '%s' "$GEMINI_JSON" | jq -r '.credential.inline.api_key'
printf '%s' "$GEMINI_JSON" | jq -r '.endpoint.base_url'
```

Map them as:

- API key: `credential.inline.api_key`
- Base URL: `endpoint.base_url`

This repo validated the Gemini key path with OpenCode rather than a specific VS
Code extension, so treat the exact extension wiring as extension-specific.

## AWS Bedrock

Use a Bedrock-capable extension with the raw Bedrock binding values.

```bash
BEDROCK_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-bedrock-0505)
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.access_key_id'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.secret_access_key'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.region'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.bedrock_endpoint'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.models'
```

Map them as:

- `access_key_id`
- `secret_access_key`
- `region`
- `bedrock_endpoint`
- `models`

## Azure Foundry preview

The current Foundry preview binding is still an Azure OpenAI-style transitional
contract, not a true Foundry RBAC flow.

```bash
FOUNDRY_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-foundry-0505c)
printf '%s' "$FOUNDRY_JSON" | jq -r '.endpoint.base_url'
printf '%s' "$FOUNDRY_JSON" | jq -r '.endpoint.api_version'
printf '%s' "$FOUNDRY_JSON" | jq -r '.credential.inline.deployment_name'
```

The currently validated live instance exposes only `text-embedding-3-small`, so
it is useful for embedding-compatible tooling, not general chat completions.
