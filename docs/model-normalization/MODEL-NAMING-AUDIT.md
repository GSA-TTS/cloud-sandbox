# Model Naming Audit & Fixes — Cross-Broker Analysis

**Goal**: Ensure model names declared in broker YAMLs match OpenCode/LiteLLM expectations with explicit output normalization.

---

## Current State Analysis

### AWS Bedrock (`csb-bedrock`)

**YAML Declaration** (aws-bedrock.yml):
```yaml
models: '["us.anthropic.claude-opus-4-6-v1","google.gemma-3-12b-it",...]'
```

**Normalized Output** (terraform/bedrock/bind/outputs.tf):
```
allowed_models = ["us.anthropic.claude-opus-4-6-v1", "google.gemma-3-12b-it", ...]
```

**OpenCode Expectation**:
```
amazon-bedrock/us.anthropic.claude-opus-4-6-v1
amazon-bedrock/google.gemma-3-12b-it
```

**Issue**: Model IDs don't have OpenCode provider prefix in binding output.

**Fix**: Add `opencode_model_names` field mapping broker model IDs → `amazon-bedrock/<model_id>`.

---

### Azure OpenAI (`csb-azure-openai`)

**YAML Declaration** (azure-openai.yml):
```yaml
deployments_json: '[{"name":"gpt-5-3-codex","model":"gpt-5.3-codex","version":"2026-02-24",...}]'
```

**Normalized Output** (terraform/azure-openai/bind/outputs.tf):
```
deployment_names = ["gpt-5-3-codex", "gpt-5-4", "gpt-5-4-mini", "gpt-5-5"]
```

**OpenCode Expectation**:
```
sandbox-azure-openai/gpt-5-3-codex
sandbox-azure-openai/gpt-5-4
sandbox-azure-openai/gpt-5-4-mini
sandbox-azure-openai/gpt-5-5
```

**Issue**: Deployment names are used instead of "gpt-5-4-mini" (Azure SDK naming vs. OpenCode naming).

**Fix**: Extract deployment names explicitly; add OpenCode-compatible model listing.

---

### Azure Foundry (`csb-azure-foundry`)

**YAML Declaration** (azure-foundry.yml):
```yaml
# Currently no explicit model declaration
# Defaults to single deployment
```

**Issue**: No model names exposed; embedding-only currently.

**Fix**: Add `deployment_name` to output; when chat-enabled, expose in normalized binding.

---

### GCP Vertex AI (`csb-google-vertex-ai`)

**YAML Declaration** (google-vertex-ai.yml):
```yaml
models: '["gemini-2.5-flash","gemini-2.5-pro","claude-sonnet-4-6",...]'
```

**Normalized Output** (terraform/vertex-ai/bind/outputs.tf):
```
allowed_models = ["gemini-2.5-flash", "gemini-2.5-pro", ...]
```

**OpenCode Expectation**:
```
google-vertex/gemini-2.5-flash
google-vertex/gemini-2.5-pro
```

**Issue**: Model IDs don't have provider prefix; some models use `@` version syntax.

**Fix**: Normalize model names; add provider-prefixed `opencode_model_names`.

---

### GCP Gemini API (`csb-google-gemini`)

**YAML Declaration** (google-gemini.yml):
```yaml
models: '["gemini-2.5-flash","gemini-2.5-pro","gemini-3.1-pro-preview",...]'
```

**Normalized Output** (terraform/gemini/bind/outputs.tf):
```
allowed_models = ["gemini-2.5-flash", "gemini-2.5-pro", ...]
```

**OpenCode Expectation**:
```
sandbox-gemini/gemini-2.5-flash
sandbox-gemini/gemini-2.5-pro
```

**Issue**: Model IDs don't have `sandbox-gemini/` prefix.

**Fix**: Add `opencode_model_names` field with normalized names.

---

## Normalization Rules

### AWS Bedrock
- **Broker Model ID**: `us.anthropic.claude-opus-4-6-v1`
- **OpenCode Name**: `amazon-bedrock/us.anthropic.claude-opus-4-6-v1`
- **LiteLLM Name**: Same as OpenCode
- **Mapping**: `<opencode_provider>/<broker_model_id>`

### Azure OpenAI
- **Broker Deployment Name**: `gpt-5-4-mini`
- **OpenCode Name**: `sandbox-azure-openai/gpt-5-4-mini`
- **LiteLLM Name**: Same as OpenCode (OpenAI-compatible)
- **Mapping**: `<opencode_provider>/<deployment_name>`

### Azure Foundry (Chat-enabled future)
- **Broker Deployment Name**: `gpt-5-4-mini`
- **OpenCode Name**: `sandbox-foundry/gpt-5-4-mini`
- **LiteLLM Name**: Same as OpenCode
- **Mapping**: `<opencode_provider>/<deployment_name>`

### GCP Vertex
- **Broker Model ID**: `gemini-2.5-flash`
- **OpenCode Name**: `google-vertex/gemini-2.5-flash`
- **LiteLLM Name**: Same as OpenCode
- **Mapping**: `<opencode_provider>/<broker_model_id>`

### GCP Gemini API
- **Broker Model ID**: `gemini-2.5-flash`
- **OpenCode Name**: `sandbox-gemini/gemini-2.5-flash`
- **LiteLLM Name**: Same as OpenCode
- **Mapping**: `<opencode_provider>/<broker_model_id>`

---

## Implementation Steps

### 1. AWS Bedrock Fixes
- **File**: `terraform/bedrock/bind/outputs.tf`
- **Add**: `opencode_model_names` with provider prefix `amazon-bedrock/`
- **Add**: `litellm_model_names` (same as opencode for this provider)
- **Test**: Verify 10 models in normalized output have correct naming

### 2. Azure OpenAI Fixes
- **File**: `terraform/azure-openai/bind/outputs.tf`
- **Add**: `opencode_deployment_names` with provider prefix `sandbox-azure-openai/`
- **Add**: `litellm_model_names` (same as opencode)
- **Ensure**: Deployment names are consistent across provision/bind
- **Test**: Verify 4 deployments in normalized output

### 3. Azure Foundry Fixes
- **File**: `terraform/azure-foundry/bind/outputs.tf`
- **Add**: `deployment_name` to output
- **Add**: `opencode_model_names` (empty array until chat-enabled)
- **Add**: `litellm_model_names` (empty array until chat-enabled)
- **Test**: Verify embedding-only caveat documented

### 4. GCP Vertex Fixes
- **File**: `terraform/vertex-ai/bind/outputs.tf`
- **Add**: `opencode_model_names` with provider prefix `google-vertex/`
- **Add**: `litellm_model_names` (same as opencode)
- **Handle**: Model versions with `@` syntax consistently
- **Test**: Verify 15 models have correct naming

### 5. GCP Gemini Fixes
- **File**: `terraform/gemini/bind/outputs.tf`
- **Add**: `opencode_model_names` with provider prefix `sandbox-gemini/`
- **Add**: `litellm_model_names` (same as opencode)
- **Test**: Verify 19 models have correct naming

---

## Test Suite Structure

Each broker will include tests in the same location as other service broker tests:

### Test Location Convention
```
terraform/<service>/<mode>/tests/
  - model_naming_test.tf     # Terraform test for model output format
  - variables_test.tf        # Test variable defaults
```

### Test Categories
1. **Model Declaration Tests**: Verify YAML models exist in provider/region
2. **Output Format Tests**: Verify normalized_binding_json structure
3. **Name Mapping Tests**: Verify OpenCode/LiteLLM names are generated correctly
4. **Integration Tests**: Verify credentials + model names can invoke models

### Example Test (AWS Bedrock)
```hcl
# terraform/bedrock/bind/tests/model_naming_test.tf
terraform {
  required_version = ">= 1.5"
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

# Test: Verify normalized_binding_json structure
output "test_normalized_binding_has_opencode_names" {
  value = can(jsondecode(local.normalized_binding).credential.opencode_model_names) ? "PASS" : "FAIL"
}

# Test: Verify all models have amazon-bedrock/ prefix
output "test_all_models_have_provider_prefix" {
  value = alltrue([
    for name in jsondecode(local.normalized_binding).credential.opencode_model_names :
    startswith(name, "amazon-bedrock/")
  ]) ? "PASS" : "FAIL"
}

# Test: Verify model count matches YAML
output "test_model_count_matches_yaml" {
  value = length(jsondecode(local.normalized_binding).credential.opencode_model_names) == 10 ? "PASS" : "FAIL"
}
```

---

## PR Strategy

### PR 1: AWS Bedrock Model Normalization
- **Branch**: `feat/bedrock-model-normalization`
- **Changes**:
  - Add `opencode_model_names` output in terraform/bedrock/bind/outputs.tf
  - Add tests for model naming
  - Update YAML to be explicit about model list
- **Tests**: 15+ assertions on model naming

### PR 2: Azure OpenAI Model Normalization
- **Branch**: `feat/azure-openai-model-normalization`
- **Changes**:
  - Add `opencode_deployment_names` output
  - Ensure deployment JSON structure consistency
  - Add tests
- **Tests**: 10+ assertions

### PR 3: Azure Foundry Model Normalization
- **Branch**: `feat/azure-foundry-model-normalization`
- **Changes**:
  - Add deployment_name + opencode_model_names (empty for now)
  - Add tests for embedding-only caveat
- **Tests**: 5+ assertions

### PR 4: GCP Vertex Model Normalization
- **Branch**: `feat/vertex-ai-model-normalization`
- **Changes**:
  - Add `opencode_model_names` with provider prefix
  - Handle model version syntax
  - Add tests
- **Tests**: 20+ assertions

### PR 5: GCP Gemini Model Normalization
- **Branch**: `feat/gemini-api-model-normalization`
- **Changes**:
  - Add `opencode_model_names` with provider prefix
  - Add tests
- **Tests**: 25+ assertions

---

## Validation Checklist

After all PRs merged and deployed:

- [ ] AWS Bedrock binding includes `opencode_model_names` with `amazon-bedrock/` prefix (10 models)
- [ ] Azure OpenAI binding includes `opencode_deployment_names` with `sandbox-azure-openai/` prefix (4 models)
- [ ] Azure Foundry binding includes `deployment_name` field (1 model)
- [ ] GCP Vertex binding includes `opencode_model_names` with `google-vertex/` prefix (15 models)
- [ ] GCP Gemini binding includes `opencode_model_names` with `sandbox-gemini/` prefix (19 models)
- [ ] OpenCode can invoke models using prefixed names
- [ ] LiteLLM can parse credentials from normalized binding
- [ ] All 27 validated models can be invoked end-to-end

---

## Documentation Updates Needed

1. **README.md**: Update model naming examples to use provider prefixes
2. **docs/ai-api-working-models.md**: Add section on model naming conventions
3. **docs/ai-api-config-extraction.md**: Show how to extract OpenCode-compatible names from binding
4. **Inline YAML docs**: Add comments explaining model naming expectations
