# AI API Configuration Extraction — Zed & OpenCode

This guide provides ready-to-use extraction scripts for all five AI brokers,
outputting valid API configurations for both Zed and OpenCode.

## Quick Reference Table

| Provider | Broker Instance | Working Models | Zed Config Path | OpenCode Provider |
| --- | --- | --- | --- | --- |
| AWS Bedrock | `verify-bedrock-0505` | 50+ Anthropic, Meta, Google, Mistral | `.aws/credentials` + env vars | `amazon-bedrock` (built-in) |
| GCP Vertex AI | `verify-vertex-0505` | 20+ Gemini, Claude, Gemma | Service account JSON | `google-vertex` (built-in) |
| GCP Gemini API | `verify-gemini-0505b` | 20+ Gemini, Gemma models | API key | `sandbox-gemini` (custom) |
| Azure OpenAI | `verify-openai-eastus2-0511095227` | GPT 5.5, 5.4, 5.4-mini, 5.3-codex | Endpoint + API key | `sandbox-azure-openai` (custom) |
| Azure Foundry | `verify-foundry-0505c` | 1 deployment (currently embedding-only) | Endpoint + API key | `sandbox-foundry` (custom) |

## 0. Prerequisites

- `cf` logged into `<cf-org>/<cf-space>`
- A scratch app bound to the instances: `bash scripts/local-agent-vcap.sh <app> <instance>`
- For OpenCode: `pnpm run opencode:broker-session -- <command>`

## 1. AWS Bedrock

### Extract credentials for Zed

```bash
set +u
BEDROCK_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-bedrock-0505)

AWS_ACCESS_KEY_ID=$(printf '%s' "$BEDROCK_JSON" | jq -r '.credential.inline.access_key_id')
AWS_SECRET_ACCESS_KEY=$(printf '%s' "$BEDROCK_JSON" | jq -r '.credential.inline.secret_access_key')
AWS_REGION=$(printf '%s' "$BEDROCK_JSON" | jq -r '.endpoint.region')

# Write to ~/.aws/credentials
aws configure --profile bedrock-sandbox \
  --region "$AWS_REGION"

# Or export as env vars for one-off use
export AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY
export AWS_REGION

# List available models
bash scripts/local-agent-vcap.sh --normalized scratch-app verify-bedrock-0505 | \
  jq -r '.grant.allowed_models[]' | head -n 20
```

### Use in Zed

Add to `~/.config/zed/settings.json`:

```json
{
  "assistant": {
    "default_model": {
      "provider": "amazon_bedrock",
      "model": "anthropic.claude-opus-4-1-20250805"
    }
  }
}
```

Then use `cmd-shift-a` in Zed to open the assistant.

### Use in OpenCode

```bash
bash scripts/launch-opencode-broker-session.sh run --model amazon-bedrock/anthropic.claude-opus-4-1-20250805 "hello"
```

---

## 2. GCP Vertex AI

### Extract credentials for Zed

```bash
set +u
VERTEX_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-vertex-0505)

VERTEX_PROJECT=$(printf '%s' "$VERTEX_JSON" | \
  jq -r '.credential.inline.credentials_json | fromjson | .project_id')
VERTEX_REGION=$(printf '%s' "$VERTEX_JSON" | jq -r '.endpoint.region')
VERTEX_CREDS=$(printf '%s' "$VERTEX_JSON" | jq -r '.credential.inline.credentials_json')

# Write service account key to disk
printf '%s' "$VERTEX_CREDS" > ~/.config/gcloud/vertex-bedrock-sandbox.json

# Set env vars
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/vertex-bedrock-sandbox.json
export GOOGLE_CLOUD_PROJECT="$VERTEX_PROJECT"
export VERTEX_LOCATION="$VERTEX_REGION"

# List available models (via broker grant)
bash scripts/local-agent-vcap.sh --normalized scratch-app verify-vertex-0505 | \
  jq -r '.grant.allowed_models[]' | head -n 20
```

### Use in Zed

Add to `~/.config/zed/settings.json`:

```json
{
  "assistant": {
    "default_model": {
      "provider": "google_ai",
      "model": "gemini-2.5-flash"
    }
  }
}
```

### Use in OpenCode

```bash
bash scripts/launch-opencode-broker-session.sh run --model google-vertex/gemini-2.5-flash "hello"
```

---

## 3. GCP Gemini API (key-based)

### Extract credentials for Zed

```bash
set +u
GEMINI_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-gemini-0505b)

GEMINI_API_KEY=$(printf '%s' "$GEMINI_JSON" | jq -r '.credential.inline.api_key')

# Export for direct use
export GEMINI_API_KEY

# List available models (these come from the live Gemini API catalog)
bash scripts/local-agent-vcap.sh --normalized scratch-app verify-gemini-0505b | \
  jq -r '.grant.allowed_models[]' | head -n 20
```

### Use in Zed

Add to `~/.config/zed/settings.json`:

```json
{
  "assistant": {
    "default_model": {
      "provider": "google_ai",
      "model": "gemini-2.5-flash"
    }
  }
}
```

### Use in OpenCode

```bash
bash scripts/launch-opencode-broker-session.sh run --model sandbox-gemini/gemini-2.5-flash "hello"
```

---

## 4. Azure OpenAI

### Extract credentials for Zed

```bash
set +u
AZURE_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-openai-eastus2-0511095227)

AZURE_ENDPOINT=$(printf '%s' "$AZURE_JSON" | jq -r '.credentials.endpoint')
AZURE_API_KEY=$(printf '%s' "$AZURE_JSON" | jq -r '.credentials.api_key')
AZURE_API_VERSION=$(printf '%s' "$AZURE_JSON" | jq -r '.credentials.api_version')

# Print deployments available (model names for use in Zed/OpenCode)
printf '%s' "$AZURE_JSON" | jq -r '.credentials.deployments | fromjson | .[].name' | head -n 10

# Export for use
export AZURE_OPENAI_API_KEY="$AZURE_API_KEY"
export AZURE_OPENAI_ENDPOINT="$AZURE_ENDPOINT"
export AZURE_OPENAI_API_VERSION="$AZURE_API_VERSION"
```

### Use in Zed

Add to `~/.config/zed/settings.json`:

```json
{
  "assistant": {
    "default_model": {
      "provider": "openai",
      "model": "gpt-5-4-mini"
    }
  }
}
```

Configure with endpoint override:

```bash
# Add these to your shell profile
export OPENAI_API_KEY="$AZURE_API_KEY"
export OPENAI_API_BASE="$AZURE_ENDPOINT/openai/v1"
```

### Use in OpenCode

```bash
bash scripts/launch-opencode-broker-session.sh run --model sandbox-azure-openai/gpt-5-4-mini "hello"
```

---

## 5. Azure Foundry (Preview)

### Extract credentials for Zed

```bash
set +u
FOUNDRY_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-foundry-0505c)

FOUNDRY_ENDPOINT=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.endpoint.base_url')
FOUNDRY_API_KEY=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.credential.inline.api_key')
FOUNDRY_DEPLOYMENT=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.credential.inline.deployment_name')

# Print the single deployment available
printf "Deployment: %s\n" "$FOUNDRY_DEPLOYMENT"

# Export for use
export AZURE_OPENAI_API_KEY="$FOUNDRY_API_KEY"
export AZURE_OPENAI_ENDPOINT="$FOUNDRY_ENDPOINT"
export AZURE_OPENAI_API_VERSION="2024-02-01"
```

### Current Status

⚠️ **Embedding-only**: The current `verify-foundry-0505c` instance only has `text-embedding-3-small`
deployed. For chat-capable Foundry usage, reprovision with a chat model parameter:

```bash
cf create-service csb-azure-foundry sandbox-8h foundry-chat -c '{
  "resource_group":"csb-foundry-chat",
  "deployment_name":"gpt-5-4-mini",
  "model_name":"gpt-5.4-mini",
  "model_version":"2026-03-17",
  "model_capacity":10
}'
```

---

## 6. Unified OpenCode Session

Launch all five brokers in one OpenCode session:

```bash
bash scripts/launch-opencode-broker-session.sh

# Then use any of these model families:
opencode models amazon-bedrock        # Built-in Bedrock
opencode models google-vertex         # Built-in Vertex
opencode models sandbox-gemini        # Custom Gemini API
opencode models sandbox-azure-openai  # Custom Azure OpenAI
opencode models sandbox-foundry       # Custom Foundry (if chat-capable)
```

Test all at once:

```bash
bash scripts/launch-opencode-broker-session.sh run --model sandbox-azure-openai/gpt-5-4-mini "test"
bash scripts/launch-opencode-broker-session.sh run --model sandbox-gemini/gemini-2.5-flash "test"
bash scripts/launch-opencode-broker-session.sh run --model amazon-bedrock/anthropic.claude-opus-4-1-20250805 "test"
```

---

## 7. Validation & Testing

### Validate all models at once

```bash
pnpm run opencode:validate:brokers
```

This writes a timestamped report to `.cache/opencode-validations/opencode-broker-validation-*.json`
with pass/fail status for all 60+ models across all five brokers.

### Extract passing models only

```bash
jq '.results[] | select(.run_status == "passed") | .broker_model_id' \
  .cache/opencode-validations/opencode-broker-validation-*.json | \
  sort | uniq
```

### Refresh model catalogs locally

If models go out of sync with what the brokers expose:

```bash
pnpm run catalog:refresh          # All three providers
pnpm run catalog:refresh:aws      # AWS only
pnpm run catalog:refresh:azure    # Azure only
pnpm run catalog:refresh:gcp      # GCP only
```

Catalogs are written to `.cache/model-catalogs/` and include pricing and context-window metadata
when available from the cloud CLIs.

---

## 8. Troubleshooting

### "Model not found" in OpenCode

The broker might expose the model in its grant list, but OpenCode's provider SDK doesn't support it yet.
Check the validation report:

```bash
jq '.results[] | select(.broker_model_id | contains("your-model")) | {id, status, notes}' \
  .cache/opencode-validations/opencode-broker-validation-*.json
```

### CF token expired

Re-authenticate with:

```bash
cf login -a api.fr.cloud.gov --sso
```

Then select org `<cf-org>` and space `<cf-space>`.

### Service instance binding fails

Make sure the instance exists and is healthy:

```bash
cf service verify-bedrock-0505   # Check status
cf service-key verify-bedrock-0505 scratch-app  # View binding if manually created
```

If the binding is missing, create it:

```bash
cf bind-service scratch-app verify-bedrock-0505
cf restage scratch-app
```

---

## 9. Production Use

Once validated, use these credentials in your application code:

**Python (LangChain/LiteLLM)**:

```python
import os
from langchain.llms import AmazonBedrock, VertexAI, ChatOpenAI

# Bedrock
bedrock = AmazonBedrock(
    region_name=os.getenv("AWS_REGION"),
    credentials_profile_name="bedrock-sandbox"
)

# Vertex
vertex = VertexAI(
    project=os.getenv("GOOGLE_CLOUD_PROJECT"),
    location=os.getenv("VERTEX_LOCATION")
)

# Azure OpenAI
azure = ChatOpenAI(
    api_key=os.getenv("AZURE_OPENAI_API_KEY"),
    api_base=os.getenv("AZURE_OPENAI_ENDPOINT"),
    model="gpt-5-4-mini"
)
```

**Node.js (Vercel AI SDK)**:

```javascript
import { openai } from "@ai-sdk/openai";
import { bedrock } from "@ai-sdk/amazon-bedrock";

const model = openai("gpt-5-4-mini", {
  baseURL: process.env.AZURE_OPENAI_ENDPOINT + "/openai/v1",
  apiKey: process.env.AZURE_OPENAI_API_KEY,
});
```

---
