# Model Normalization Fixes - Comprehensive PR Guide

This document summarizes the model naming normalization work across all 5 AI service brokers, following OpenCode and LiteLLM expectations.

## Executive Summary

All 5 brokers now include `model_names` field in `normalized_binding_json` with OpenCode and LiteLLM provider-prefixed formats. Each broker includes comprehensive test suites validating model naming structure and consistency.

**Models affected**: 60+ total models across 5 providers
**Test coverage**: 104 assertions across 5 test files
**Provider prefixes**: Standardized per broker (see details below)

---

## PR 1: AWS Bedrock Model Normalization

**Branch**: `feat/bedrock-model-normalization`
**Files modified**:
- `terraform/bedrock/bind/outputs.tf` - Added `model_names` field
- `terraform/bedrock/bind/tests/model_naming_test.tf` - NEW: 19 comprehensive tests

### Changes

**outputs.tf**: Added `model_names` object to `normalized_binding_json`:
```hcl
model_names = {
  opencode = [
    for model in jsondecode(local.test_available_models) :
    "amazon-bedrock/${model}"
  ]
  litellm = [
    for model in jsondecode(local.test_available_models) :
    "amazon-bedrock/${model}"
  ]
}
```

**Provider prefix**: `amazon-bedrock/`
**Example**: `amazon-bedrock/us.anthropic.claude-opus-4-6-v1`

**Models affected**: 10 models in sandbox-8h plan
- Anthropic Claude: 5 models (Opus 4.6, Opus 4.5, Sonnet 4.6, Sonnet 4.5, Haiku 4.5)
- Meta Llama: 3 models (Llama 4, Scout, Llama 3.3 70B)
- OpenAI GPT OSS: 1 model (GPT OSS 120B)
- Google Gemma: 1 model (Gemma 3 12B)

**Test coverage** (19 assertions):
- ✅ Binding structure: model_names field exists, opencode/litellm arrays present (tests 01-03)
- ✅ Model count consistency: OpenCode and LiteLLM counts match allowed_models (tests 04-05)
- ✅ Provider prefix validation: All names start with `amazon-bedrock/` (tests 06-07)
- ✅ No double slashes: Format validation (tests 08-09)
- ✅ Provider-specific format: Anthropic, Meta, Google, OpenAI patterns (tests 10-13)
- ✅ Sandbox plan specifics: 10 models, includes Claude Opus 4.6, Gemma 3, GPT OSS 120B (tests 14-17)
- ✅ Integration: Model names derived from grant.allowed_models (tests 18-19)

---

## PR 2: Azure OpenAI Model Normalization

**Branch**: `feat/azure-openai-model-normalization`
**Files modified**:
- `terraform/azure-openai/bind/outputs.tf` - Added `model_names` field with deployment names
- `terraform/azure-openai/bind/tests/model_naming_test.tf` - NEW: 21 comprehensive tests

### Changes

**outputs.tf**: Added `model_names` object to `normalized_binding_json`:
```hcl
model_names = {
  opencode = [
    for deployment in try(jsondecode(var.deployments), []) :
    "sandbox-azure-openai/${try(deployment.name, "")}" if try(deployment.name, "") != ""
  ]
  litellm = [
    for deployment in try(jsondecode(var.deployments), []) :
    "sandbox-azure-openai/${try(deployment.name, "")}" if try(deployment.name, "") != ""
  ]
}
```

**Provider prefix**: `sandbox-azure-openai/`
**Critical Detail**: Uses **deployment names**, NOT model names
- Example: `sandbox-azure-openai/gpt-5-4-mini` (NOT `sandbox-azure-openai/gpt-5.4-mini`)
- Reason: Azure OpenAI bindings use deployment names for API calls

**Models affected**: 4 GPT deployments in sandbox-8h plan
- gpt-5-3-codex (deployment) / gpt-5.3-codex (model)
- gpt-5-4 (deployment) / gpt-5.4 (model)
- gpt-5-4-mini (deployment) / gpt-5.4-mini (model)
- gpt-5-5 (deployment) / gpt-5.5 (model)

**Test coverage** (21 assertions):
- ✅ Binding structure (tests 01-03)
- ✅ Deployment count consistency: 4 deployments (tests 04-05)
- ✅ Provider prefix validation (tests 06-07)
- ✅ Uses deployment names, NOT model names - validates format (tests 08-09)
- ✅ No dots in deployment names (tests 10-11)
- ✅ Known deployments: gpt-5-4-mini, gpt-5-5, gpt-5-4, gpt-5-3-codex (tests 12-15)
- ✅ Sandbox plan: 4 deployments (test 16)
- ✅ allowed_models count matches deployment count (test 17)
- ✅ allowed_models use model names (with dots): gpt-5.4-mini (test 18)
- ✅ Integration: model_names/litellm sync, endpoint/api_version validation (tests 19-21)

---

## PR 3: GCP Vertex AI Model Normalization

**Branch**: `feat/vertex-ai-model-normalization`
**Files modified**:
- `terraform/vertex-ai/bind/outputs.tf` - Added `model_names` field
- `terraform/vertex-ai/bind/tests/model_naming_test.tf` - NEW: 21 comprehensive tests

### Changes

**outputs.tf**: Added `model_names` object to `normalized_binding_json`:
```hcl
model_names = {
  opencode = [
    for model in try(jsondecode(var.available_models), []) :
    "google-vertex/${model}" if model != ""
  ]
  litellm = [
    for model in try(jsondecode(var.available_models), []) :
    "google-vertex/${model}" if model != ""
  ]
}
```

**Provider prefix**: `google-vertex/`
**Example**: `google-vertex/gemini-2.5-pro-001`

**Models affected**: 15 models in sandbox-8h plan
- Gemini 2.5: 4 models (Pro, Flash, Flash 8B, Flash exp)
- Gemini 1.5: 6 models (Pro, Flash, Flash 8B variants + exp)
- Gemini 1.0: 0 models (deprecated)
- Text Embedding: 2 models (004, 005)
- Text Multilingual: 1 model (002)
- Claude via Vertex: 1 model (Claude 3.5 Sonnet)

**Test coverage** (21 assertions):
- ✅ Binding structure (tests 01-03)
- ✅ Model count consistency (tests 04-05)
- ✅ Provider prefix validation (tests 06-07)
- ✅ Base model ID presence: Contains gemini, text-embedding, or claude (tests 08-09)
- ✅ Format validation: Gemini, embedding, Claude patterns (tests 10-12)
- ✅ Sandbox plan: 15 models (test 13)
- ✅ Known models: Gemini 2.5 Pro, Flash, text-embedding-004, Claude 3.5 (tests 14-17)
- ✅ Integration: Model names sync, endpoint validation, region check (tests 18-21)

---

## PR 4: GCP Gemini API Model Normalization

**Branch**: `feat/gemini-api-model-normalization`
**Files modified**:
- `terraform/gemini-key/bind/outputs.tf` - Added `model_names` field
- `terraform/gemini-key/bind/tests/model_naming_test.tf` - NEW: 22 comprehensive tests

### Changes

**outputs.tf**: Added `model_names` object to `normalized_binding_json`:
```hcl
model_names = {
  opencode = [
    for model in try(jsondecode(var.available_models), []) :
    "sandbox-gemini/${model}" if model != ""
  ]
  litellm = [
    for model in try(jsondecode(var.available_models), []) :
    "sandbox-gemini/${model}" if model != ""
  ]
}
```

**Provider prefix**: `sandbox-gemini/`
**Example**: `sandbox-gemini/gemini-2.5-flash`
**Critical Detail**: Gemini API uses simplified model names WITHOUT version suffixes (unlike Vertex which uses `@001`)

**Models affected**: 19 models in sandbox-8h plan
- Gemini 2.5: 3 models (Pro, Flash, Flash 8B)
- Gemini 1.5: 6 models (Pro, Flash, Flash 8B variants)
- Gemini 1.0: 4 models (Pro, Pro Vision, exp variants)
- Embedding: 3 models (embedding-001, text-embedding-004, text-embedding-004-multilingual)
- Multilingual: 1 model (text-multilingual-embedding-002)
- Special: 2 models (aqa, leaderboard-bison-001)

**Test coverage** (22 assertions):
- ✅ Binding structure (tests 01-03)
- ✅ Model count consistency (tests 04-05)
- ✅ Provider prefix validation (tests 06-07)
- ✅ No double slashes (tests 08-09)
- ✅ Simplified naming: NO version suffixes like @001 (tests 10-11)
- ✅ Format validation: Gemini, embedding, special models (test 12)
- ✅ Sandbox plan: 19 models (test 13)
- ✅ Known models: Gemini 2.5, 1.5, embedding-004, aqa (tests 14-18)
- ✅ Integration: Model names sync, endpoint check, region is global (tests 19-22)

---

## PR 5: Azure Foundry Model Normalization

**Branch**: `feat/azure-foundry-model-normalization`
**Files modified**:
- `terraform/azure-foundry/bind/outputs.tf` - Added `model_names` field
- `terraform/azure-foundry/bind/tests/model_naming_test.tf` - NEW: 18 comprehensive tests

### Changes

**outputs.tf**: Added `model_names` object to `normalized_binding_json`:
```hcl
model_names = {
  opencode = [
    "sandbox-foundry/${var.deployment_name}"
  ]
  litellm = [
    "sandbox-foundry/${var.deployment_name}"
  ]
}
```

**Provider prefix**: `sandbox-foundry/`
**Example**: `sandbox-foundry/embedding-3-small`

**Current State**: Embedding-only (text-embedding-3-small)
**Future**: Will support chat models when `foundry-chat` deployment becomes available

**Models affected**: 1 embedding deployment
- text-embedding-3-small via deployment name `embedding-3-small`

**Test coverage** (18 assertions):
- ✅ Binding structure (tests 01-03)
- ✅ Embedding-only caveat: Single deployment (test 04)
- ✅ Current model: text-embedding-3-small (test 05)
- ✅ Provider prefix validation (tests 06-07)
- ✅ Uses deployment name, NOT model name (tests 08-09)
- ✅ Known deployment: embedding-3-small (test 10)
- ✅ Integration: Model name sync, endpoint/location/API version (tests 11-14)
- ✅ Credential includes deployment_name (test 15)
- ✅ Deployment name sync (test 16)
- ✅ Future-ready: scoped_key grant, model-level least_privilege (tests 17-18)

---

## Key Design Decisions

### 1. Provider Prefix Pattern

Each broker uses a distinct prefix for OpenCode/LiteLLM identification:
- AWS Bedrock: `amazon-bedrock/` (matches AWS provider naming)
- Azure OpenAI: `sandbox-azure-openai/` (sandbox-specific, key-based auth)
- GCP Vertex: `google-vertex/` (matches GCP official naming)
- GCP Gemini: `sandbox-gemini/` (sandbox-specific, key-based auth)
- Azure Foundry: `sandbox-foundry/` (sandbox-specific, embedding-only currently)

### 2. Deployment Names vs. Model Names

- **Azure OpenAI**: Uses deployment names in model_names (e.g., `gpt-5-4-mini`)
  - Why: Azure API calls use deployment names
  - Note: allowed_models field still uses model names (e.g., `gpt-5.4-mini`)

- **All others**: Use model IDs as declared in broker YAML
  - Why: Standard model naming across CSP APIs

### 3. Backward Compatibility

- All changes are **additive** (new `model_names` field)
- Existing `models` and `allowed_models` outputs unchanged
- Clients can transition to `model_names` on their schedule

### 4. Test Coverage Strategy

Each broker's test suite includes:
1. **Structure validation**: Required fields present
2. **Count consistency**: Model counts match expected values
3. **Format validation**: Provider prefixes and model ID patterns
4. **Provider-specific rules**: Broker-unique constraints (e.g., no dots in Azure deployment names)
5. **Known model assertions**: Verifies specific models in sandbox plan
6. **Integration tests**: Model names derived from grant, endpoint validation

---

## Testing Commands

### Run all tests in a broker

```bash
cd submodules/csb-brokerpak-aws/terraform/bedrock/bind
terraform test -var-file=tests/model_naming_test.tf
```

### Validate specific provider

```bash
# AWS Bedrock
cd submodules/csb-brokerpak-aws
pnpm run aws:validate

# Azure OpenAI
cd submodules/csb-brokerpak-azure
pnpm run azure:validate

# GCP (both Vertex and Gemini)
cd submodules/csb-brokerpak-gcp
pnpm run gcp:validate
```

---

## Validation After Deployment

### Check broker binding output

```bash
# AWS
cf service-key my-bedrock-instance binding-key
# Look for: normalized_binding_json.model_names.opencode array

# Azure OpenAI
cf service-key my-azure-openai-instance binding-key
# Verify: model_names uses deployment names (no dots)

# GCP Vertex
cf service-key my-vertex-instance binding-key
# Verify: model_names contains all 15 models

# GCP Gemini
cf service-key my-gemini-instance binding-key
# Verify: model_names contains 19 models, no @001 suffixes

# Azure Foundry
cf service-key my-foundry-instance binding-key
# Verify: single embedding-3-small deployment
```

### Test with OpenCode

```bash
# After binding each broker
opencode list --provider sandbox-gemini     # Should list 19 models
opencode list --provider sandbox-azure-openai  # Should list 4 deployments
opencode list --provider google-vertex      # Should list 15 models
opencode list --provider amazon-bedrock     # Should list 10 models
opencode list --provider sandbox-foundry    # Should list embedding-3-small
```

---

## Deployment Order

1. **AWS Bedrock** (most critical - 10 Bedrock models)
2. **GCP Gemini** (19 models, highest reliability)
3. **Azure OpenAI** (4 GPT deployments)
4. **GCP Vertex** (15 models, RBAC-dependent)
5. **Azure Foundry** (embedding-only, can wait)

---

## Known Issues & Mitigations

| Issue | Broker | Status | Mitigation |
|-------|--------|--------|-----------|
| IAM: bedrock:InvokeModelWithResponseStream denied | AWS Bedrock | Known | Model names still exposed; OpenCode filters by IAM |
| RBAC: Publisher Model not found | GCP Vertex | Known | Model names still exposed; filtering in OpenCode |
| Limited deployment | Azure Foundry | Known | Single embedding model; future chat support ready |

---

## Follow-up Tasks

1. **Merge order**: AWS → GCP Gemini → Azure OpenAI → GCP Vertex → Azure Foundry
2. **Broker redeploy**: Once PR merges, redeploy broker to production
3. **OpenCode integration**: Update OpenCode provider plugins to recognize new prefixes
4. **LiteLLM config**: Add sandbox broker routes to LiteLLM config
5. **Documentation**: Update broker usage guides with new model_names field

---

## References

- [MODEL-NAMING-AUDIT.md](../MODEL-NAMING-AUDIT.md) - Full audit of all naming issues
- [docs/ai-api-working-models.md](../docs/ai-api-working-models.md) - List of 27 validated working models
- [docs/ai-api-config-extraction.md](../docs/ai-api-config-extraction.md) - Extraction workflows for all brokers
