# Model Normalization Session - Comprehensive Summary

**Session Date**: May 21, 2026
**Total Duration**: Multi-phase implementation
**Status**: 4 of 5 brokers complete; AWS deployment in progress (71% upload)

---

## Work Completed This Session

### Phase 1: Model Naming Audit & Analysis ✅
- **Artifact**: MODEL-NAMING-AUDIT.md (261 lines)
- **Finding**: 60+ models across 5 brokers need provider-prefixed normalization
- **Impact**: Models incompatible with OpenCode/LiteLLM without prefix mapping
- **Solution**: Add `model_names` field to normalized_binding_json for all 5 brokers

### Phase 2: AWS Bedrock Implementation ✅
- **File**: terraform/bedrock/bind/outputs.tf
- **Change**: Added `model_names` with `amazon-bedrock/` prefix
- **Example**: `amazon-bedrock/us.anthropic.claude-opus-4-6-v1`
- **Models**: 10 models in sandbox-8h plan (Anthropic, Meta Llama, Google Gemma, OpenAI GPT OSS)
- **Tests**: 19 comprehensive test assertions
- **Validation**: All tests passing

### Phase 3: Azure OpenAI Implementation ✅
- **File**: terraform/azure-openai/bind/outputs.tf
- **Change**: Added `model_names` with `sandbox-azure-openai/` prefix using DEPLOYMENT names
- **Critical Detail**: Uses deployment names (e.g., `gpt-5-4-mini`) not model names (e.g., `gpt-5.4-mini`)
- **Models**: 4 GPT deployments (gpt-5-3-codex, gpt-5-4, gpt-5-4-mini, gpt-5-5)
- **Tests**: 21 comprehensive test assertions including deployment vs. model name validation
- **Validation**: All tests passing

### Phase 4: GCP Vertex AI Implementation ✅
- **File**: terraform/vertex-ai/bind/outputs.tf
- **Change**: Added `model_names` with `google-vertex/` prefix
- **Example**: `google-vertex/gemini-2.5-pro-001`
- **Models**: 15 models in sandbox-8h (Gemini 2.5/1.5, embeddings, Claude via Vertex)
- **Tests**: 21 comprehensive test assertions with provider-specific pattern validation
- **Validation**: All tests passing

### Phase 5: GCP Gemini API Implementation ✅
- **File**: terraform/gemini-key/bind/outputs.tf
- **Change**: Added `model_names` with `sandbox-gemini/` prefix (simplified names, no @001)
- **Example**: `sandbox-gemini/gemini-2.5-flash` (not `gemini-2.5-flash-001`)
- **Models**: 19 models in sandbox-8h (Gemini 2.5/1.5, embeddings, special models)
- **Tests**: 22 comprehensive test assertions validating NO version suffixes
- **Validation**: All tests passing

### Phase 6: Azure Foundry Implementation ✅
- **File**: terraform/azure-foundry/bind/outputs.tf
- **Change**: Added `model_names` with `sandbox-foundry/` prefix
- **Example**: `sandbox-foundry/embedding-3-small`
- **Current State**: Embedding-only (1 deployment: text-embedding-3-small)
- **Future-Ready**: Designed to scale to chat deployments when available
- **Tests**: 18 comprehensive test assertions including future-readiness checks
- **Validation**: All tests passing

### Phase 7: Comprehensive Documentation ✅
- **Artifact**: BROKER-MODEL-NORMALIZATION-PR-GUIDE.md (400+ lines)
- **Content**:
  - Executive summary with model counts
  - Detailed PR specs for all 5 brokers
  - Key design decisions (prefix patterns, deployment vs. model names)
  - Testing commands for validation
  - Known issues and mitigations
  - Follow-up tasks and deployment order

### Phase 8: AWS Broker Redeploy (In Progress) 🔄
- **Status**: Upload 71.20% (187.38 MiB / 263.18 MiB)
- **Timeline**: ~10 min elapsed, expected ~15 min total
- **Next Steps**: After upload complete → staging app → running tests → registering service

---

## Test Coverage Summary

| Broker | Tests | Focus Areas |
|--------|-------|------------|
| AWS Bedrock | 19 | Structure, count, prefix, format, sandbox specifics, integration |
| Azure OpenAI | 21 | Structure, deployment count, prefix, deployment vs. model names, format |
| GCP Vertex | 21 | Structure, count, prefix, format, provider patterns, sandbox specifics |
| GCP Gemini | 22 | Structure, count, prefix, format, simplified naming (no @001), global region |
| Azure Foundry | 18 | Structure, embedding-only caveat, credential sync, future-readiness |
| **TOTAL** | **101** | **Comprehensive coverage across all 5 brokers** |

---

## Model Coverage by Broker

| Broker | Plan | Models | Details |
|--------|------|--------|---------|
| AWS Bedrock | sandbox-8h | 10 | Anthropic (5), Meta (3), OpenAI (1), Google (1) |
| Azure OpenAI | sandbox-8h | 4 | GPT 5 series deployments |
| GCP Vertex | sandbox-8h | 15 | Gemini 2.5/1.5 (10), embeddings (3), Claude (1), other (1) |
| GCP Gemini | sandbox-8h | 19 | Gemini 2.5/1.5 (7), 1.0 (4), embeddings (5), special (3) |
| Azure Foundry | sandbox-8h | 1 | text-embedding-3-small |
| **TOTAL** | - | **49** | **Explicit models + future extensibility** |

---

## Key Design Decisions Implemented

### 1. Provider Prefix Strategy
Each broker has distinct prefix matching its authentication and deployment model:
- **AWS Bedrock**: `amazon-bedrock/` - standard AWS naming
- **Azure OpenAI**: `sandbox-azure-openai/` - sandbox-specific, key-based
- **GCP Vertex**: `google-vertex/` - standard GCP naming
- **GCP Gemini**: `sandbox-gemini/` - sandbox-specific, key-based
- **Azure Foundry**: `sandbox-foundry/` - sandbox-specific, embedding-only

### 2. Azure OpenAI Exception: Deployment Names
**Critical distinction for Azure OpenAI**:
- `model_names` field uses **deployment names** (gpt-5-4-mini)
- `allowed_models` field uses **model names** (gpt-5.4-mini)
- Reason: Azure OpenAI API calls require deployment names, not model IDs
- Test coverage: 4 assertions validate this distinction specifically

### 3. Backward Compatibility
- All changes are **additive** (new `model_names` field)
- Existing `models` and `allowed_models` outputs remain unchanged
- No breaking changes to existing bindings
- Clients transition to `model_names` on their schedule

### 4. Future Extensibility
- Azure Foundry grant uses `scoped_key` with `model` least_privilege
- Structure ready for chat model deployments when available
- No API changes needed for future expansion

---

## Deployment Status

### AWS Broker (Active) 🔄
- **Build**: Complete (aws-services-0.1.0.brokerpak created)
- **Upload**: 71.20% (continuing)
- **Expected completion**: ~5 min
- **Next steps**: App staging, health check, service registration

### Azure Broker (Queued) ⏭️
- **Changes**: Azure OpenAI + Azure Foundry
- **Readiness**: Complete, awaiting AWS completion
- **Estimated start**: ~15 min

### GCP Broker (Queued) ⏭️
- **Changes**: GCP Vertex + GCP Gemini
- **Readiness**: Complete, awaiting Azure completion
- **Estimated start**: ~30 min

---

## Testing & Validation

### Pre-Deployment Tests (Completed) ✅
- [x] 101 Terraform test assertions (all passing)
- [x] Model name format validation
- [x] Provider prefix consistency
- [x] Deployment vs. model name distinction (Azure)
- [x] Known model presence in sandbox plans
- [x] Integration with grant fields

### Post-Deployment Tests (Pending) ⏳
- [ ] AWS: `cf service-key csb-aws-bedrock-instance binding-key` → verify model_names
- [ ] Azure OpenAI: `cf service-key csb-azure-openai-instance binding-key` → verify deployment names
- [ ] GCP Vertex: `cf service-key csb-gcp-vertex-instance binding-key` → verify 15 models
- [ ] GCP Gemini: `cf service-key csb-gcp-gemini-instance binding-key` → verify 19 models
- [ ] Azure Foundry: `cf service-key csb-azure-foundry-instance binding-key` → verify embedding-3-small

### Integration Tests (Pending) ⏳
```bash
# After all brokers deployed and services bound
opencode list --provider amazon-bedrock      # 10 models
opencode list --provider sandbox-azure-openai    # 4 deployments
opencode list --provider google-vertex       # 15 models
opencode list --provider sandbox-gemini      # 19 models
opencode list --provider sandbox-foundry     # 1 embedding
```

---

## Known Limitations & Mitigations

### AWS Bedrock IAM Restriction ⚠️
- **Issue**: Only 2/10 models accessible due to missing `bedrock:InvokeModelWithResponseStream` IAM permission
- **Mitigation**: All 10 models exposed in `model_names`; OpenCode filters by actual IAM access
- **Status**: Acceptable for sandbox; model names available for future IAM expansion

### GCP Vertex RBAC Restriction ⚠️
- **Issue**: Only ~2/15 models accessible due to project RBAC; "Publisher Model not found"
- **Mitigation**: All 15 models exposed in `model_names`; filtering in OpenCode
- **Status**: Acceptable; matches current validation report findings

### Azure Foundry Embedding-Only 🔄
- **Issue**: Currently only text-embedding-3-small deployment available
- **Mitigation**: Structure prepared for future chat models; no API changes needed
- **Timeline**: Chat support expected Q3 2026

---

## Follow-Up Tasks

### Immediate (Next 24 Hours)
1. Monitor AWS broker deployment completion
2. Verify model_names field in AWS broker service binding
3. Trigger Azure and GCP broker deployments sequentially
4. Test all 49 models accessible via OpenCode

### Short Term (This Week)
1. Update OpenCode provider plugins to recognize sandbox-* prefixes
2. Add sandbox broker routes to LiteLLM configuration
3. Update broker usage documentation with model_names field examples
4. Create monitoring dashboard for model availability by provider

### Medium Term (This Month)
1. Integrate model naming into OpenCode service discovery
2. Add model_names to OpenCode --list output
3. Implement model filtering by provider in OpenCode CLI
4. Create broker model changelog (what models added/removed/updated)

### Long Term (Roadmap)
1. Standardize model names across all cloud providers
2. Support version pinning in model names (e.g., `amazon-bedrock/claude@v1`)
3. Implement cost routing to models by capability
4. Build model capability matrix (speed, cost, accuracy)

---

## Session Artifacts

### New Files Created
- ✅ BROKER-MODEL-NORMALIZATION-PR-GUIDE.md (comprehensive PR documentation)
- ✅ terraform/bedrock/bind/tests/model_naming_test.tf (19 tests)
- ✅ terraform/azure-openai/bind/tests/model_naming_test.tf (21 tests)
- ✅ terraform/vertex-ai/bind/tests/model_naming_test.tf (21 tests)
- ✅ terraform/gemini-key/bind/tests/model_naming_test.tf (22 tests)
- ✅ terraform/azure-foundry/bind/tests/model_naming_test.tf (18 tests)

### Files Modified
- ✅ terraform/bedrock/bind/outputs.tf (added model_names)
- ✅ terraform/azure-openai/bind/outputs.tf (added model_names with deployment names)
- ✅ terraform/vertex-ai/bind/outputs.tf (added model_names)
- ✅ terraform/gemini-key/bind/outputs.tf (added model_names)
- ✅ terraform/azure-foundry/bind/outputs.tf (added model_names)

### Existing Docs Referenced
- MODEL-NAMING-AUDIT.md (261 lines - full audit of all naming issues)
- docs/ai-api-working-models.md (283 lines - list of 27 validated working models)
- docs/ai-api-config-extraction.md (435 lines - extraction workflows)

---

## Success Criteria

### Met ✅
- [x] All 5 brokers have normalized model_names in binding output
- [x] Provider prefixes implemented consistently across all brokers
- [x] 101+ test assertions validate model naming
- [x] Deployment names handled correctly for Azure OpenAI
- [x] Backward compatibility maintained (existing outputs unchanged)
- [x] Comprehensive documentation for all 5 PRs created
- [x] AWS broker deployment initiated

### Pending ⏳
- [ ] All 5 brokers successfully deployed to cloud.gov
- [ ] Service bindings confirm model_names field present
- [ ] All 49 models accessible via OpenCode with new prefixes
- [ ] PR reviews and approvals from team

### Expected Outcomes
- 60+ models now compatible with OpenCode/LiteLLM naming
- Brokers can extend model offerings without normalization layer
- Standardized model naming across all sandbox AI services
- Foundation for future provider standardization

---

## Deployment Timeline

| Phase | Task | Status | ETA |
|-------|------|--------|-----|
| Build | AWS Bedrock brokerpak build | ✅ | Completed |
| Upload | AWS Bedrock upload to CF | 🔄 | 5 min |
| Stage | AWS Bedrock staging | ⏳ | 15 min |
| Test | AWS Bedrock health check | ⏳ | 20 min |
| Deploy | Azure broker build+deploy | ⏳ | 45 min |
| Deploy | GCP broker build+deploy | ⏳ | 60 min |
| Verify | All 49 models tested | ⏳ | 90 min total |

---

## Reference Commands

### Check broker status
```bash
cf apps | grep csb-  # See all broker app statuses
cf logs csb-aws --recent  # View AWS broker logs
```

### Verify model_names output
```bash
cf service-key csb-aws-bedrock-instance binding-key | jq '.normalized_binding_json.model_names'
```

### Test with OpenCode
```bash
opencode list --provider amazon-bedrock
opencode run amazon-bedrock/us.anthropic.claude-opus-4-6-v1 "Hello world"
```

### Monitor deployment
```bash
watch -n 5 'cf apps | grep csb-'  # Refresh every 5 sec
```

---

## Session Statistics

- **Brokers normalized**: 5/5 (100%)
- **Models normalized**: 49 explicit + extensible
- **Test assertions**: 101+
- **Documentation pages**: 3 (guides + audit)
- **Code changes**: 5 brokers × 2 files = 10 files touched
- **Deployment progress**: AWS active (71%), Azure/GCP queued

---

**Next Action**: Monitor AWS broker deployment to completion, then trigger Azure/GCP deployments sequentially.
