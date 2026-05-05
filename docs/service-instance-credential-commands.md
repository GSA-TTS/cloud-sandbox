# Service Instance Credential Commands

This document is the shortest path from a deployed broker to usable local
credentials.

It covers:

1. Creating a service instance
2. Waiting for the instance to finish provisioning
3. Extracting the returned credentials from `VCAP_SERVICES`
4. Exporting provider-specific environment variables for local tools

## Prerequisites

- `cf` CLI installed and logged into cloud.gov
- Access to `<organization>  / <space>`
- Brokers already deployed in the target space
- A reusable CF app named `scratch-app`
- `jq` installed locally

Target the sandbox space first:

```bash
cf target -o <organization> -s <space>
```

## Common Pattern

Create an instance:

```bash
cf create-service <marketplace-service> <plan> <instance-name> -c '{}'
```

Poll until provisioning finishes:

```bash
cf service <instance-name>
```

Print the normalized binding payload:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app <instance-name>
```

Print the raw binding payload:

```bash
bash scripts/local-agent-vcap.sh scratch-app <instance-name>
```

## AWS Bedrock

Create the instance:

```bash
cf create-service csb-aws-bedrock sandbox-8h local-bedrock -c '{}'
```

Check status:

```bash
cf service local-bedrock
```

Print normalized credentials:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app local-bedrock
```

Export AWS variables:

```bash
export AWS_ACCESS_KEY_ID="$(bash scripts/local-agent-vcap.sh scratch-app local-bedrock | jq -r '.credentials.access_key_id')"
export AWS_SECRET_ACCESS_KEY="$(bash scripts/local-agent-vcap.sh scratch-app local-bedrock | jq -r '.credentials.secret_access_key')"
export AWS_REGION_NAME="$(bash scripts/local-agent-vcap.sh scratch-app local-bedrock | jq -r '.credentials.region')"
```

## GCP Vertex AI

Create the instance:

```bash
cf create-service csb-google-vertex-ai sandbox-8h local-vertex -c '{}'
```

Check status:

```bash
cf service local-vertex
```

Print normalized credentials:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app local-vertex
```

Write the service account key to disk and export LiteLLM-compatible Vertex
variables:

```bash
bash scripts/local-agent-vcap.sh scratch-app local-vertex | jq -r '.credentials.credentials_json' > vertex-credentials.json
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/vertex-credentials.json"
export VERTEXAI_PROJECT="$(bash scripts/local-agent-vcap.sh scratch-app local-vertex | jq -r '.credentials.project_id')"
export VERTEXAI_LOCATION="$(bash scripts/local-agent-vcap.sh scratch-app local-vertex | jq -r '.credentials.region')"
```

## GCP Gemini API

Create the instance:

```bash
cf create-service csb-google-gemini sandbox-8h local-gemini -c '{}'
```

Check status:

```bash
cf service local-gemini
```

Print normalized credentials:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app local-gemini
```

Export the Gemini API key:

```bash
export GEMINI_API_KEY="$(bash scripts/local-agent-vcap.sh --normalized scratch-app local-gemini | jq -r '.credential.inline.api_key')"
```

If you want the raw broker field instead of the normalized contract:

```bash
bash scripts/local-agent-vcap.sh scratch-app local-gemini | jq -r '.credentials.api_key'
```

## Azure OpenAI

Create the instance:

```bash
cf create-service csb-azure-openai sandbox-8h local-openai -c '{}'
```

The Azure OpenAI offering now enables the same default GPT deployment set on
both `sandbox-8h` and `standard`: `gpt-5.5`, `gpt-5.4`, `gpt-5.4-mini`,
`gpt-5.3-codex`, and `gpt-5.2`. `gpt-5.5` is first in the default deployment
payload and should be treated as the default chat target. Pass a
`deployments_json` override only when the target subscription or region cannot
support the full matrix.

Check status:

```bash
cf service local-openai
```

Print normalized credentials:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app local-openai
```

Export Azure OpenAI variables:

```bash
export AZURE_API_KEY="$(bash scripts/local-agent-vcap.sh scratch-app local-openai | jq -r '.credentials.api_key')"
export AZURE_API_BASE="$(bash scripts/local-agent-vcap.sh scratch-app local-openai | jq -r '.credentials.endpoint')"
export AZURE_API_VERSION="$(bash scripts/local-agent-vcap.sh scratch-app local-openai | jq -r '.credentials.api_version')"
```

## Azure Foundry Preview

Create the preview per-model instance:

```bash
cf create-service csb-azure-foundry sandbox-8h local-foundry -c '{"resource_group":"csb-foundry-local","foundry_hub_name":"sandbox-hub","foundry_project_name":"sandbox-project","deployment_name":"text-embedding-3-small","model_name":"text-embedding-3-small","model_version":"1","model_capacity":10}'
```

Check status:

```bash
cf service local-foundry
```

Print the normalized binding payload:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app local-foundry
```

Print the raw binding payload:

```bash
bash scripts/local-agent-vcap.sh scratch-app local-foundry
```

Export the Foundry-aligned Azure OpenAI key and model details:

```bash
export FOUNDRY_OPENAI_API_KEY="$(bash scripts/local-agent-vcap.sh scratch-app local-foundry | jq -r '.credentials.api_key')"
export FOUNDRY_OPENAI_API_BASE="$(bash scripts/local-agent-vcap.sh scratch-app local-foundry | jq -r '.credentials.endpoint')"
export FOUNDRY_OPENAI_API_VERSION="$(bash scripts/local-agent-vcap.sh scratch-app local-foundry | jq -r '.credentials.api_version')"
export FOUNDRY_MODEL_NAME="$(bash scripts/local-agent-vcap.sh scratch-app local-foundry | jq -r '.credentials.model_name')"
export FOUNDRY_DEPLOYMENT_NAME="$(bash scripts/local-agent-vcap.sh scratch-app local-foundry | jq -r '.credentials.deployment_name')"
```

The service now returns a usable Azure OpenAI key and single-model deployment
metadata, but it remains a transitional preview rather than a true Foundry
RBAC-backed credential flow.

In this sandbox, pass an explicit `resource_group` for Foundry instances. The
Azure broker currently applies a global fallback resource group through
`GSB_PROVISION_DEFAULTS`, and the explicit parameter avoids colliding with that
shared group.

## One-Liners for Existing Validated Instances

These are the currently validated instance names used in the sandbox space:

- AWS Bedrock: `verify-bedrock-0505`
- GCP Vertex AI: `verify-vertex-0505`
- GCP Gemini API: `verify-gemini-0505b`
- Azure OpenAI: `verify-openai-0505b`

Example: print the current Gemini API key from the validated instance:

```bash
bash scripts/local-agent-vcap.sh --normalized scratch-app verify-gemini-0505b | jq -r '.credential.inline.api_key'
```

Example: print the current Azure OpenAI endpoint from the validated instance:

```bash
bash scripts/local-agent-vcap.sh scratch-app verify-openai-0505b | jq -r '.credentials.endpoint'
```
