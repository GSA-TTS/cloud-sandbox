# AI API Configuration — Verified Working Models

**Last Updated**: 2026-05-18 16:28:17 UTC
**Validation Report**: `.cache/opencode-validations/opencode-broker-validation-2026-05-18-16-28-17-.json`
**Status**: 27 confirmed working ✅ | 26 known issues ⚠️ | 3 unsupported | 6 not in OpenCode catalog

## Quick Start — Copy & Paste Ready

### For Zed

```bash
# 1. Set env vars for your chosen provider
source <(bash scripts/extract-ai-configs.sh)

# 2. Start Zed
zed

# 3. In Zed, open the assistant: Cmd+Shift+A
```

### For OpenCode

```bash
# 1. Launch unified broker session
bash scripts/launch-opencode-broker-session.sh

# 2. Test any model:
opencode run --model sandbox-azure-openai/gpt-5-4-mini "hello"
```

---

## 27 Confirmed Working Models

### AWS Bedrock (2 working)

| Model | OpenCode Path | Status |
| --- | --- | --- |
| `openai.gpt-oss-120b-1:0` | `amazon-bedrock/openai.gpt-oss-120b-1:0` | ✅ Passed |
| `google.gemma-3-12b-it` | `amazon-bedrock/google.gemma-3-12b-it` | ✅ Passed |

**Known issues** (25 models failing with Bedrock IAM permissions):
- Anthropic Claude series (blocked by `bedrock:InvokeModelWithResponseStream` permission)
- Mistral, Meta Llama, and other models restricted by IAM policy

**Action**: Verify broker IAM user has `bedrock:InvokeModel*` actions in policy.

### GCP Vertex AI (2 working)

| Model | OpenCode Path | Status |
| --- | --- | --- |
| `gemini-2.5-flash` | `google-vertex/gemini-2.5-flash` | ✅ Passed |
| `gemini-2.5-pro` | `google-vertex/gemini-2.5-pro` | ✅ Passed |

**Known issues** (13 models with project access restrictions):
- `gemini-3.1-pro-preview`, `gemini-3-pro-preview`, and others return "Publisher Model not found or project does not have access"

**Action**: Update Vertex broker service account IAM roles to include `roles/vertexai.modelAgentUser` or adjust model grant list in service definition.

### GCP Gemini API (19 working) 🌟

All Gemini API models accessible via key-based authentication:

| Model | OpenCode Path | Status |
| --- | --- | --- |
| `gemini-2.5-flash` | `sandbox-gemini/gemini-2.5-flash` | ✅ Passed |
| `gemini-2.5-pro` | `sandbox-gemini/gemini-2.5-pro` | ✅ Passed |
| `gemini-2.0-flash-lite` | `sandbox-gemini/gemini-2.0-flash-lite` | ✅ Passed |
| `gemma-4-26b-a4b-it` | `sandbox-gemini/gemma-4-26b-a4b-it` | ✅ Passed |
| `gemma-4-31b-it` | `sandbox-gemini/gemma-4-31b-it` | ✅ Passed |
| `gemini-flash-latest` | `sandbox-gemini/gemini-flash-latest` | ✅ Passed |
| `gemini-flash-lite-latest` | `sandbox-gemini/gemini-flash-lite-latest` | ✅ Passed |
| `gemini-pro-latest` | `sandbox-gemini/gemini-pro-latest` | ✅ Passed |
| `gemini-2.5-flash-lite` | `sandbox-gemini/gemini-2.5-flash-lite` | ✅ Passed |
| `gemini-3-pro-preview` | `sandbox-gemini/gemini-3-pro-preview` | ✅ Passed |
| `gemini-3-flash-preview` | `sandbox-gemini/gemini-3-flash-preview` | ✅ Passed |
| `gemini-3.1-pro-preview` | `sandbox-gemini/gemini-3.1-pro-preview` | ✅ Passed |
| `gemini-3.1-pro-preview-customtools` | `sandbox-gemini/gemini-3.1-pro-preview-customtools` | ✅ Passed |
| `gemini-3.1-flash-lite-preview` | `sandbox-gemini/gemini-3.1-flash-lite-preview` | ✅ Passed |
| `gemini-3.1-flash-lite` | `sandbox-gemini/gemini-3.1-flash-lite` | ✅ Passed |
| `gemini-3-pro-image-preview` | `sandbox-gemini/gemini-3-pro-image-preview` | ✅ Passed |
| `nano-banana-pro-preview` | `sandbox-gemini/nano-banana-pro-preview` | ✅ Passed |
| `gemini-3.1-flash-image-preview` | `sandbox-gemini/gemini-3.1-flash-image-preview` | ✅ Passed |
| `gemini-robotics-er-1.6-preview` | `sandbox-gemini/gemini-robotics-er-1.6-preview` | ✅ Passed |

**Recommended for Zed**: Use `sandbox-gemini/gemini-2.5-flash` or `sandbox-gemini/gemini-2.5-pro`

### Azure OpenAI (4 working)

| Model | OpenCode Path | Status |
| --- | --- | --- |
| `gpt-5-3-codex` | `sandbox-azure-openai/gpt-5-3-codex` | ✅ Passed |
| `gpt-5-4` | `sandbox-azure-openai/gpt-5-4` | ✅ Passed |
| `gpt-5-4-mini` | `sandbox-azure-openai/gpt-5-4-mini` | ✅ Passed |
| `gpt-5-5` | `sandbox-azure-openai/gpt-5-5` | ✅ Passed |

**Recommended for Zed**: Use `sandbox-azure-openai/gpt-5-4-mini` (balanced latency/cost)

---

## Zed Configuration

### Step 1: Extract credentials

```bash
source <(bash scripts/extract-ai-configs.sh)
```

### Step 2: Update Zed settings

Edit `~/.config/zed/settings.json`:

```json
{
  "assistant": {
    "default_model": {
      "provider": "openai",
      "model": "gpt-4o"
    }
  }
}
```

### Step 3: Export env vars in shell profile

Add to `~/.zshrc` or `~/.bashrc`:

```bash
# For Azure OpenAI (recommended)
export OPENAI_API_KEY='[your-azure-api-key]'
export OPENAI_API_BASE='[your-azure-endpoint]/openai/v1'
export OPENAI_MODEL_NAME='gpt-5-4-mini'

# Or for Gemini API
export GEMINI_API_KEY='[your-gemini-api-key]'
```

### Step 4: Use Zed Assistant

In Zed:
- Press `Cmd+Shift+A` to open the assistant
- Type your question
- Zed reads env vars to route requests to your configured provider

**If assistant doesn't appear**:
1. Check Zed version: `zed --version` (needs 0.1.305+)
2. Ensure env vars are exported: `echo $OPENAI_API_KEY`
3. Restart Zed

---

## OpenCode Configuration

### Step 1: Launch broker session

```bash
bash scripts/launch-opencode-broker-session.sh
```

This sets up configs for all five brokers: AWS Bedrock, GCP Vertex, GCP Gemini, Azure OpenAI, Azure Foundry.

### Step 2: Test a model

```bash
opencode run --model sandbox-azure-openai/gpt-5-4-mini "hello"
```

Expected output:
```
Response: hi
```

### Step 3: List available models per provider

```bash
opencode models amazon-bedrock      # 2 models
opencode models google-vertex       # 2 models
opencode models sandbox-gemini      # 19 models (best choice!)
opencode models sandbox-azure-openai # 4 models
opencode models sandbox-foundry     # 1 model (embedding-only)
```

### Step 4: Interactive chat

```bash
opencode run --model sandbox-gemini/gemini-2.5-flash
# Type questions interactively, Ctrl+D to exit
```

---

## Troubleshooting

### "Model not found in OpenCode catalog"

Some broker models aren't registered with OpenCode's provider SDKs yet.

**Solution**: Check validation report for "unsupported" status:

```bash
jq '.results[] | select(.run_status=="unsupported") | .broker_model_id' \
  .cache/opencode-validations/*.json | sort | uniq
```

### "Permission denied" in Bedrock

IAM policy too restrictive. Verify broker policy includes:

```json
{
  "Action": [
    "bedrock:InvokeModel",
    "bedrock:InvokeModelWithResponseStream"
  ],
  "Resource": "*",
  "Effect": "Allow"
}
```

Script to update: `bash scripts/iam-bootstrap-aws.sh <user> <profile>`

### "Project does not have access" in Vertex

Service account missing Vertex AI permissions.

**Solution**: Grant service account role:

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:SA_EMAIL \
  --role=roles/vertexai.modelAgentUser
```

Or update broker service definition to use different model grant list.

### CF token expired

Re-authenticate:

```bash
cf login -a api.fr.cloud.gov --sso
# Select org: gsa-tts-iae-lava-beds
# Select space: dev
```

---

## Environment Variables Reference

### AWS Bedrock

```bash
export AWS_ACCESS_KEY_ID='...'
export AWS_SECRET_ACCESS_KEY='...'
export AWS_REGION='us-east-1'
```

### GCP Vertex AI

```bash
export GOOGLE_APPLICATION_CREDENTIALS='~/.config/gcloud/vertex-sandbox.json'
export GOOGLE_CLOUD_PROJECT='project-id'
export VERTEX_LOCATION='us-central1'
```

### GCP Gemini API

```bash
export GEMINI_API_KEY='...'
```

### Azure OpenAI

```bash
export AZURE_OPENAI_API_KEY='...'
export AZURE_OPENAI_ENDPOINT='https://...openai.azure.com/'
export AZURE_OPENAI_API_VERSION='2024-08-01-preview'
```

### Azure Foundry

```bash
export FOUNDRY_OPENAI_API_KEY='...'
export FOUNDRY_OPENAI_API_BASE='https://...openai.azure.com/'
export FOUNDRY_OPENAI_API_VERSION='2024-02-01'
export FOUNDRY_MODEL_NAME='gpt-5-4-mini'
export FOUNDRY_DEPLOYMENT_NAME='gpt-5-4-mini'
```

---

## Next Steps

1. **Zed + Azure OpenAI**: Quickest path with 4 confirmed models
2. **OpenCode + Gemini**: Most models available (19 working)
3. **Bedrock or Vertex**: Requires IAM/RBAC fixes before reliable use
4. **Foundry**: Currently embedding-only; plan to enable chat models later

See `docs/ai-api-config-extraction.md` for detailed step-by-step instructions.
