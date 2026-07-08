#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

app_name="${OPENCODE_BROKER_APP_NAME:-scratch-app}"
bedrock_instance="${OPENCODE_BEDROCK_INSTANCE:-verify-bedrock-0505}"
vertex_instance="${OPENCODE_VERTEX_INSTANCE:-verify-vertex-0505}"
gemini_instance="${OPENCODE_GEMINI_INSTANCE:-verify-gemini-0505b}"
azure_instance="${OPENCODE_AZURE_INSTANCE:-verify-openai-eastus2-0511095227}"
foundry_instance="${OPENCODE_FOUNDRY_INSTANCE:-verify-foundry-0505c}"
output_file="${OPENCODE_BROKER_CONFIG_OUTPUT:-${REPO_ROOT}/.opencode/opencode.jsonc}"
global_output_file="${OPENCODE_BROKER_GLOBAL_CONFIG_OUTPUT:-${HOME}/.config/opencode/opencode.jsonc}"

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: required command not found: $cmd" >&2
    exit 1
  fi
}

require_cmd jq
require_cmd curl
require_cmd rg

json_array_arg_from_lines() {
  jq -Rn '[inputs | select(length > 0)]'
}

models_object_from_lines() {
  jq -Rn '[inputs | select(length > 0)] | map({key: ., value: {}}) | from_entries'
}

latest_validation_report() {
  local latest
  latest="$(find "${REPO_ROOT}/.cache/opencode-validations" -maxdepth 1 -type f -name 'opencode-broker-validation-*.json' 2>/dev/null | sort | tail -n 1)"
  [[ -n "$latest" ]] || return 1
  printf '%s\n' "$latest"
}

filter_accessible_models_from_report() {
  local provider_family="$1"
  local report_file="$2"
  shift 2

  if [[ -z "$report_file" || ! -f "$report_file" ]]; then
    printf '%s\n' "$@"
    return 0
  fi

  printf '%s\n' "$@" | jq -R -s 'split("\n") | map(select(length > 0))' | jq -r \
    --arg provider_family "$provider_family" \
    --slurpfile report "$report_file" \
    '
      . as $models
      | ($report[0].results // []) as $results
      | ($results
          | map(select(
              .provider_family == $provider_family
              and .run_status == "failed"
              and ((.notes // "") | test("not found or your project does not have access|status\\\": \\\"NOT_FOUND\\\"|is not authorized to perform|forbidden:"; "i"))
            ))
          | map(.broker_model_id)
          | unique) as $blocked
          | $models[] as $model
          | select(($blocked | index($model)) == null)
          | $model
    '
}

mkdir -p "$(dirname "$output_file")"
mkdir -p "$(dirname "$global_output_file")"

bedrock_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$bedrock_instance")"
vertex_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$vertex_instance")"
gemini_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$gemini_instance")"
azure_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$azure_instance")"
azure_raw_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" "$app_name" "$azure_instance")"
foundry_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$foundry_instance")"
foundry_raw_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" "$app_name" "$foundry_instance")"

validation_report="$(latest_validation_report || true)"

mapfile -t bedrock_models < <(printf '%s' "$bedrock_json" | jq -r '.grant.allowed_models[]')
mapfile -t vertex_models < <(printf '%s' "$vertex_json" | jq -r '.grant.allowed_models[]')
mapfile -t azure_models < <(printf '%s' "$azure_raw_json" | jq -r '.credentials.deployments | fromjson | .[].name')
mapfile -t foundry_models < <(printf '%s' "$foundry_raw_json" | jq -r '.credentials.deployment_name')

mapfile -t vertex_models < <(filter_accessible_models_from_report "google_vertex_identity" "$validation_report" "${vertex_models[@]}")
mapfile -t vertex_models < <(printf '%s\n' "${vertex_models[@]}" | rg -vx 'claude-opus-4-6|claude-sonnet-4-6' || true)

gemini_api_key="$(printf '%s' "$gemini_json" | jq -r '.credential.inline.api_key')"
gemini_base_url="$(printf '%s' "$gemini_json" | jq -r '.endpoint.base_url')"
gemini_models_json="$(curl -fsS "${gemini_base_url%/}/v1beta/models?key=${gemini_api_key}")"
mapfile -t gemini_models < <(printf '%s' "$gemini_models_json" | jq -r '.models[] | select(((.supportedGenerationMethods // []) | index("generateContent")) != null) | .name | sub("^models/"; "")')

azure_base_url="$(printf '%s' "$azure_json" | jq -r '.endpoint.base_url')"
azure_base_url="${azure_base_url%/}/openai/v1"

foundry_base_url="$(printf '%s' "$foundry_json" | jq -r '.endpoint.base_url')"
foundry_base_url="${foundry_base_url%/}/openai/v1"

foundry_embedding_only=0
if printf '%s\n' "${foundry_models[@]}" | rg -qi '(^|[[:punct:]])embedding([[:punct:]]|$)|^text-embedding'; then
  foundry_embedding_only=1
fi

enabled_providers=(
  "sandbox-bedrock"
  "sandbox-vertex"
  "sandbox-gemini"
  "sandbox-azure-openai"
)

if [[ "$foundry_embedding_only" -eq 0 ]]; then
  enabled_providers+=("sandbox-foundry")
fi

enabled_providers_json="$(printf '%s\n' "${enabled_providers[@]}" | json_array_arg_from_lines)"
bedrock_models_object="$(printf '%s\n' "${bedrock_models[@]}" | models_object_from_lines)"
vertex_models_object="$(printf '%s\n' "${vertex_models[@]}" | models_object_from_lines)"
gemini_models_object="$(printf '%s\n' "${gemini_models[@]}" | models_object_from_lines)"
azure_models_object="$(printf '%s\n' "${azure_models[@]}" | models_object_from_lines)"
foundry_models_object="$(printf '%s\n' "${foundry_models[@]}" | models_object_from_lines)"

generated_config="$(jq -n \
  --arg default_model "sandbox-azure-openai/gpt-5-4-mini" \
  --arg small_model "sandbox-gemini/gemini-2.5-flash" \
  --arg aws_region "$(printf '%s' "$bedrock_json" | jq -r '.endpoint.region')" \
  --arg aws_access_key_id "$(printf '%s' "$bedrock_json" | jq -r '.credential.inline.access_key_id')" \
  --arg aws_secret_access_key "$(printf '%s' "$bedrock_json" | jq -r '.credential.inline.secret_access_key')" \
  --arg vertex_project "$(printf '%s' "$vertex_json" | jq -r '.credential.inline.credentials_json | fromjson | .project_id')" \
  --arg vertex_region "$(printf '%s' "$vertex_json" | jq -r '.endpoint.region')" \
  --argjson vertex_credentials_json "$(printf '%s' "$vertex_json" | jq -c '.credential.inline.credentials_json | fromjson')" \
  --arg gemini_api_key "$gemini_api_key" \
  --arg azure_base_url "$azure_base_url" \
  --arg azure_api_key "$(printf '%s' "$azure_json" | jq -r '.credential.inline.api_key')" \
  --arg foundry_base_url "$foundry_base_url" \
  --arg foundry_api_key "$(printf '%s' "$foundry_json" | jq -r '.credential.inline.api_key')" \
  --argjson enabled_providers "$enabled_providers_json" \
  --argjson bedrock_models "$bedrock_models_object" \
  --argjson vertex_models "$vertex_models_object" \
  --argjson gemini_models "$gemini_models_object" \
  --argjson azure_models "$azure_models_object" \
  --argjson foundry_models "$foundry_models_object" \
  '
    {
      "$schema": "https://opencode.ai/config.json",
      enabled_providers: $enabled_providers,
      model: $default_model,
      small_model: $small_model,
      provider: {
        "sandbox-bedrock": {
          npm: "@ai-sdk/amazon-bedrock",
          name: "Sandbox Bedrock",
          options: {
            region: $aws_region,
            accessKeyId: $aws_access_key_id,
            secretAccessKey: $aws_secret_access_key
          },
          models: $bedrock_models
        },
        "sandbox-vertex": {
          npm: "@ai-sdk/google-vertex",
          name: "Sandbox Vertex AI",
          options: {
            project: $vertex_project,
            location: $vertex_region,
            googleCredentials: $vertex_credentials_json
          },
          models: $vertex_models
        },
        "sandbox-gemini": {
          npm: "@ai-sdk/google",
          name: "Sandbox Gemini API",
          options: {
            apiKey: $gemini_api_key
          },
          models: $gemini_models
        },
        "sandbox-azure-openai": {
          npm: "@ai-sdk/openai",
          name: "Sandbox Azure OpenAI",
          options: {
            baseURL: $azure_base_url,
            apiKey: $azure_api_key
          },
          models: $azure_models
        },
        "sandbox-foundry": {
          npm: "@ai-sdk/openai",
          name: "Sandbox Foundry Preview",
          options: {
            baseURL: $foundry_base_url,
            apiKey: $foundry_api_key
          },
          models: $foundry_models
        }
      }
    }
    | if (.enabled_providers | index("sandbox-foundry")) == null then .provider |= del(."sandbox-foundry") else . end
  ')"

printf '%s\n' "$generated_config" > "$output_file"
printf '%s\n' "$generated_config" > "$global_output_file"

echo "Wrote OpenCode broker snapshot: $output_file"
echo "Wrote OpenCode broker snapshot: $global_output_file"
echo "Restart OpenCode/Zed to pick up the generated providers."