# OpenCode Auth Configuration

This guide captures the exact OpenCode validation paths that were exercised in
the sandbox using live brokered bindings.

Validated against:

- OpenCode `1.15.4`
- `scripts/local-agent-vcap.sh`
- Cloud Foundry org `gsa-tts-iae-lava-beds`, space `dev`

## Current blockers

Two provider families need extra care because their broker-exposed model surface
is not the same thing as their usable OpenCode surface:

- Vertex AI: the broker binding currently exposes a grant list, but several of
  those model IDs are not callable in project `tts-datagov`. The observed
  failures were provider-side `Publisher Model ... was not found or your project
  does not have access` errors, not OpenCode adapter bugs.
- Azure Foundry preview: the current `verify-foundry-0505c` instance binds to an
  Azure OpenAI account that has many chat-capable models in its regional catalog,
  but the brokered instance itself only deployed `text-embedding-3-small`.
  OpenCode cannot use that deployment for chat-style `run` commands.

Practical implication:

- `scripts/launch-opencode-broker-session.sh` now prunes known inaccessible
  Vertex models from the shared session and omits Foundry entirely when the
  current binding is embedding-only.
- `scripts/refresh-model-catalogs.sh --provider azure` now records both the
  account catalog and the account's actual deployments so the gap is explicit in
  `.cache/model-catalogs/azure-openai-<location>.json`.

## How to overcome Vertex failures

For Vertex, the durable fix is not in OpenCode. One of these has to change:

1. Request access to the missing publisher models in project `tts-datagov`.
2. Update the broker's allowed model list to only advertise the validated
   callable subset.
3. Keep using the unified launcher's filtered model set, which uses the latest
   validation report to suppress known access-denied models.

To inspect the latest provider catalog for the project, use:

```bash
set +u
pnpm run catalog:refresh:gcp
```

That writes the latest Model Garden catalog to:

```text
.cache/model-catalogs/gcp-vertex-model-garden-<project>.json
```

Important caveat: this is the latest provider catalog, not a guarantee that the
bound service account can invoke every listed model. The effective OpenCode
surface is the intersection of:

- the broker grant list from `scripts/local-agent-vcap.sh --normalized`
- the latest validation report under `.cache/opencode-validations/`
- the models still present in `pnpm run opencode:broker-session -- models`

## How to overcome Foundry failures

The current Azure Foundry brokerpak defaults the single deployment to an
embedding model:

- [submodules/csb-brokerpak-azure/azure-foundry.yml](/Users/johnhjediny/Documents/GitHub/cloud-sandbox/submodules/csb-brokerpak-azure/azure-foundry.yml#L90)
- [submodules/csb-brokerpak-azure/azure-foundry.yml](/Users/johnhjediny/Documents/GitHub/cloud-sandbox/submodules/csb-brokerpak-azure/azure-foundry.yml#L97)

That default is why the current binding is unusable for OpenCode chat. To make a
Foundry-aligned instance usable for OpenCode, provision it with a chat-capable
deployment instead of `text-embedding-3-small` by setting:

- `deployment_name`
- `model_name`
- `model_version`
- optionally `model_capacity`

The account-level latest chat-capable model catalog and the current deployed
surface can now be inspected together with:

```bash
set +u
FOUNDRY_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-foundry-0505c)
RG=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.credentials.resource_group')
ACCOUNT=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.credentials.account_name')
SUB=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.credentials.azure_subscription_id')

bash scripts/refresh-model-catalogs.sh \
  --provider azure \
  --azure-location eastus \
  --azure-resource-group "$RG" \
  --azure-account-name "$ACCOUNT" \
  --azure-subscription "$SUB"
```

Then inspect:

```bash
jq '{connection, deployments, effective_connection_models}' \
  .cache/model-catalogs/azure-openai-eastus.json
```

Interpretation:

- `models`: latest regional account catalog
- `deployments`: what is actually deployed in that account now
- `effective_connection_models`: chat/responses-capable deployed models that a
  bound client can realistically use

If `effective_connection_models` is empty, the brokered Foundry instance is not
yet suitable for OpenCode chat and should stay hidden from the shared launcher.

In this session, start commands with `set +u` so inherited shell settings do not
break the temporary config snippets.

## Full broker sweep

To validate the full broker-exposed OpenCode model surface in one pass, run:

```bash
set +u
pnpm run opencode:validate:brokers
```

That writes a timestamped JSON report under:

```text
.cache/opencode-validations/
```

The current validated sweep produced:

- `62` total provider/model checks
- `53` passed
- `3` unsupported for text-style `opencode run`
- `6` broker-exposed models missing from current OpenCode model listings

Current unsupported models:

- Gemini API: `gemini-2.5-flash-preview-tts` is audio-only for response output
- Gemini API: `gemini-2.5-pro-preview-tts` is audio-only for response output
- Azure Foundry preview: `text-embedding-3-small` is embedding-only

Current broker models not listed by OpenCode:

- Bedrock: `us.meta.llama3-3-70b-instruct-v1:0`
- Vertex: `gemini-2.0-flash-001`
- Vertex: `gemini-3.1-flash`
- Vertex: `gemini-3-pro-image-preview`
- Vertex: `claude-sonnet-4-6`
- Vertex: `claude-opus-4-6`

## Validation summary

| Service family | Instance used | OpenCode path | Result |
| --- | --- | --- | --- |
| AWS Bedrock | `verify-bedrock-0505` | Built-in `amazon-bedrock` | `opencode run` succeeded |
| GCP Vertex AI | `verify-vertex-0505` | Built-in `google-vertex` | `opencode run` succeeded |
| GCP Gemini API | `verify-gemini-0505b` | Custom `@ai-sdk/google` | `opencode run` succeeded |
| Azure OpenAI | `verify-openai-eastus2-0511095227` | Custom `@ai-sdk/openai` | `opencode run` succeeded |
| Azure Foundry preview | `verify-foundry-0505c` | Custom `@ai-sdk/openai-compatible` | Models loaded, run unsupported |

## AWS Bedrock

OpenCode supports Bedrock as a built-in provider.

```bash
set +u
BEDROCK_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-bedrock-0505)
AWS_ACCESS_KEY_ID=$(printf '%s' "$BEDROCK_JSON" | jq -r '.credential.inline.access_key_id')
AWS_SECRET_ACCESS_KEY=$(printf '%s' "$BEDROCK_JSON" | jq -r '.credential.inline.secret_access_key')
AWS_REGION=$(printf '%s' "$BEDROCK_JSON" | jq -r '.endpoint.region')
TMP_BASE=$(mktemp /tmp/opencode-bedrock.XXXXXX)
TMP_CONFIG="${TMP_BASE}.json"
mv "$TMP_BASE" "$TMP_CONFIG"
cat > "$TMP_CONFIG" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "enabled_providers": ["amazon-bedrock"],
  "provider": {
    "amazon-bedrock": {
      "options": {
        "region": "$AWS_REGION"
      }
    }
  }
}
EOF
AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
AWS_REGION="$AWS_REGION" \
OPENCODE_CONFIG="$TMP_CONFIG" \
opencode run --model amazon-bedrock/google.gemma-3-12b-it "Reply with OK only."
rm -f "$TMP_CONFIG"
```

Observed result: the model replied `OK`.

## GCP Vertex AI

OpenCode supports Vertex as a built-in provider under the `google-vertex`
model prefix.

```bash
set +u
VERTEX_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-vertex-0505)
VERTEX_PROJECT=$(printf '%s' "$VERTEX_JSON" | jq -r '.credential.inline.credentials_json | fromjson | .project_id')
VERTEX_REGION=$(printf '%s' "$VERTEX_JSON" | jq -r '.endpoint.region')
VERTEX_CREDS=$(printf '%s' "$VERTEX_JSON" | jq -r '.credential.inline.credentials_json')
TMP_CREDS=$(mktemp /tmp/opencode-vertex-creds.XXXXXX.json)
printf '%s' "$VERTEX_CREDS" > "$TMP_CREDS"
GOOGLE_APPLICATION_CREDENTIALS="$TMP_CREDS" \
GOOGLE_CLOUD_PROJECT="$VERTEX_PROJECT" \
VERTEX_LOCATION="$VERTEX_REGION" \
opencode run --model google-vertex/gemini-2.5-flash "Reply with OK only."
rm -f "$TMP_CREDS"
```

Observed result: the model replied `OK`.

## GCP Gemini API key

OpenCode did not expose a built-in Gemini API-key provider in the provider docs
used here, but it worked with a custom provider backed by `@ai-sdk/google`.

```bash
set +u
GEM_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-gemini-0505b)
GEM_KEY=$(printf '%s' "$GEM_JSON" | jq -r '.credential.inline.api_key')
TMP_BASE=$(mktemp /tmp/opencode-gemini.XXXXXX)
TMP_CONFIG="${TMP_BASE}.json"
mv "$TMP_BASE" "$TMP_CONFIG"
cat > "$TMP_CONFIG" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "sandbox-gemini": {
      "npm": "@ai-sdk/google",
      "name": "Sandbox Gemini API",
      "options": {
        "apiKey": "$GEM_KEY"
      },
      "models": {
        "gemini-2.5-flash": {},
        "gemini-2.5-pro": {}
      }
    }
  },
  "enabled_providers": ["sandbox-gemini"]
}
EOF
OPENCODE_CONFIG="$TMP_CONFIG" \
opencode run --model sandbox-gemini/gemini-2.5-flash "Reply with OK only."
rm -f "$TMP_CONFIG"
```

Observed result: the model replied `OK`.

## Azure OpenAI

Azure OpenAI worked with a custom provider backed by `@ai-sdk/openai`.

Use a chat-capable Azure binding such as `verify-openai-eastus2-0511095227`, not
an embedding-only instance.

```bash
set +u
AZ_JSON=$(bash scripts/local-agent-vcap.sh scratch-app verify-openai-eastus2-0511095227)
AZ_KEY=$(printf '%s' "$AZ_JSON" | jq -r '.credentials.api_key')
AZ_ENDPOINT=$(printf '%s' "$AZ_JSON" | jq -r '.credentials.endpoint')
TMP_BASE=$(mktemp /tmp/opencode-azure.XXXXXX)
TMP_CONFIG="${TMP_BASE}.json"
mv "$TMP_BASE" "$TMP_CONFIG"
cat > "$TMP_CONFIG" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "sandbox-azure-openai": {
      "npm": "@ai-sdk/openai",
      "name": "Sandbox Azure OpenAI",
      "options": {
        "baseURL": "${AZ_ENDPOINT%/}/openai/v1",
        "apiKey": "$AZ_KEY"
      },
      "models": {
        "gpt-5-3-codex": {},
        "gpt-5-4": {},
        "gpt-5-4-mini": {},
        "gpt-5-5": {}
      }
    }
  },
  "enabled_providers": ["sandbox-azure-openai"]
}
EOF
OPENCODE_CONFIG="$TMP_CONFIG" opencode models sandbox-azure-openai
OPENCODE_CONFIG="$TMP_CONFIG" \
opencode run --model sandbox-azure-openai/gpt-5-4-mini "Reply with OK only."
rm -f "$TMP_CONFIG"
```

Observed result:

- `opencode models sandbox-azure-openai` succeeded
- `opencode run` returned `OK`

Interpretation: this Azure endpoint behaves like an OpenAI responses-style
provider for OpenCode, so `@ai-sdk/openai` is the validated adapter.

Known bad path:

- Using `@ai-sdk/openai-compatible` with the same brokered endpoint and model
  list still fails with `Unknown parameter: 'reasoningSummary'.`

## Azure Foundry preview

The current Foundry preview binding also loaded as a custom OpenAI-compatible
provider, but the validated instance only exposed an embedding deployment.

```bash
set +u
FOUNDRY_JSON=$(bash scripts/local-agent-vcap.sh --normalized scratch-app verify-foundry-0505c)
FOUNDRY_KEY=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.credential.inline.api_key')
FOUNDRY_ENDPOINT=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.endpoint.base_url')
FOUNDRY_DEPLOYMENT=$(printf '%s' "$FOUNDRY_JSON" | jq -r '.credential.inline.deployment_name')
TMP_BASE=$(mktemp /tmp/opencode-foundry.XXXXXX)
TMP_CONFIG="${TMP_BASE}.json"
mv "$TMP_BASE" "$TMP_CONFIG"
cat > "$TMP_CONFIG" <<EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "sandbox-foundry": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Sandbox Foundry Preview",
      "options": {
        "baseURL": "${FOUNDRY_ENDPOINT%/}/openai/v1",
        "apiKey": "$FOUNDRY_KEY"
      },
      "models": {
        "$FOUNDRY_DEPLOYMENT": {}
      }
    }
  },
  "enabled_providers": ["sandbox-foundry"]
}
EOF
OPENCODE_CONFIG="$TMP_CONFIG" opencode models sandbox-foundry
OPENCODE_CONFIG="$TMP_CONFIG" \
opencode run --model sandbox-foundry/$FOUNDRY_DEPLOYMENT "Reply with OK only."
rm -f "$TMP_CONFIG"
```

Observed result:

- `opencode models sandbox-foundry` listed `text-embedding-3-small`
- `opencode run` failed with `The requested operation is unsupported.`

Interpretation: the provider wiring is valid, but the live preview instance is
embedding-only and not usable for chat-style `opencode run`.
