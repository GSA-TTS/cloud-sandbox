# Zed Auth Configuration

Use this guide after the brokers are deployed and you already have a bound
service instance in the sandbox space. For the common bind-and-read workflow,
see `docs/local-agent-workflows.md`.

## Prerequisites

- `cf` logged into `gsa-tts-iae-lava-beds / dev`
- A scratch app such as `scratch-app`
- Zed installed locally

## Recommended validated instances

These are the current live instances that were used to verify the binding
shapes in this repo:

- AWS Bedrock: `verify-bedrock-0505`
- GCP Vertex AI: `verify-vertex-0505`
- Azure OpenAI: `verify-openai-eastus2-0511095227`
- Azure Foundry preview: `verify-foundry-0505c`

## Extract the binding first

Use the helper to read the current binding payload:

```bash
bash scripts/local-agent-vcap.sh scratch-app verify-bedrock-0505
bash scripts/local-agent-vcap.sh scratch-app verify-vertex-0505
bash scripts/local-agent-vcap.sh scratch-app verify-openai-eastus2-0511095227
```

If you only want the normalized contract:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app verify-bedrock-0505
```

## Azure OpenAI

Zed should use the OpenAI-compatible provider values from the Azure binding.

Extract the values:

```bash
AZURE_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-openai-eastus2-0511095227)
printf '%s' "$AZURE_JSON" | jq -r '.credentials.endpoint'
printf '%s' "$AZURE_JSON" | jq -r '.credentials.api_key'
printf '%s' "$AZURE_JSON" | jq -r '.credentials.api_version'
printf '%s' "$AZURE_JSON" | jq -r '.credentials.deployments'
```

Map them in Zed as:

- Base URL: `endpoint`
- API key: `api_key`
- API version: `api_version`
- Model name: one of the deployed names from `deployments`

Use a chat-capable deployment such as `gpt-5-4-mini` or `gpt-5-4`. Do not use
an embedding-only instance for chat.

## GCP Vertex AI

Zed's Google provider maps cleanly from the Vertex binding.

Extract the values:

```bash
VERTEX_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-vertex-0505)
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.project_id'
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.region'
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.credentials_json'
printf '%s' "$VERTEX_JSON" | jq -r '.credentials.models'
```

Map them in Zed as:

- Project: `project_id`
- Region: `region`
- Credentials: `credentials_json`
- Model list: `models`

## AWS Bedrock

Zed can use the Bedrock binding directly.

Extract the values:

```bash
BEDROCK_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-bedrock-0505)
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.access_key_id'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.secret_access_key'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.region'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.bedrock_endpoint'
printf '%s' "$BEDROCK_JSON" | jq -r '.credentials.models'
```

Map them in Zed as:

- Access key ID: `access_key_id`
- Secret access key: `secret_access_key`
- Region: `region`
- Runtime endpoint: `bedrock_endpoint`
- Allowed models: `models`

## Current caveats

- The GCP Gemini API key service exists, but this repo's Zed guidance is still
  centered on the validated Vertex AI path.
- The Azure Foundry preview binding currently exposes a usable Azure
  OpenAI-style endpoint, but the validated live instance is embedding-only.
  That makes it unsuitable for normal Zed chat use.
