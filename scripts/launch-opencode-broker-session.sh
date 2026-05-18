#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/launch-opencode-broker-session.sh [opencode-args...]

Builds a temporary OpenCode config from the live brokered Cloud Foundry service
bindings and launches OpenCode with all currently supported broker providers
available in one session.

Default broker instances:
  verify-bedrock-0505
  verify-vertex-0505
  verify-gemini-0505b
  verify-openai-eastus2-0511095227
  verify-foundry-0505c

Environment overrides:
  OPENCODE_BROKER_APP_NAME
  OPENCODE_BEDROCK_INSTANCE
  OPENCODE_VERTEX_INSTANCE
  OPENCODE_GEMINI_INSTANCE
  OPENCODE_AZURE_INSTANCE
  OPENCODE_FOUNDRY_INSTANCE

Examples:
  bash scripts/launch-opencode-broker-session.sh
  bash scripts/launch-opencode-broker-session.sh models
  bash scripts/launch-opencode-broker-session.sh run --model sandbox-azure-openai/gpt-5-4-mini "say hi"
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--" ]]; then
  shift
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

app_name="${OPENCODE_BROKER_APP_NAME:-scratch-app}"
bedrock_instance="${OPENCODE_BEDROCK_INSTANCE:-verify-bedrock-0505}"
vertex_instance="${OPENCODE_VERTEX_INSTANCE:-verify-vertex-0505}"
gemini_instance="${OPENCODE_GEMINI_INSTANCE:-verify-gemini-0505b}"
azure_instance="${OPENCODE_AZURE_INSTANCE:-verify-openai-eastus2-0511095227}"
foundry_instance="${OPENCODE_FOUNDRY_INSTANCE:-verify-foundry-0505c}"

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $cmd" >&2
    exit 1
  fi
}

resolve_opencode_bin() {
  local candidate

  if [[ -n "${OPENCODE_BIN:-}" ]]; then
    if [[ ! -x "${OPENCODE_BIN}" ]]; then
      echo "ERROR: OPENCODE_BIN is not executable: ${OPENCODE_BIN}" >&2
      exit 1
    fi
    printf '%s\n' "${OPENCODE_BIN}"
    return 0
  fi

  while IFS= read -r candidate; do
    [[ -n "$candidate" ]] || continue
    if [[ "$candidate" != *"/node_modules/.bin/"* ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done < <(which -a opencode 2>/dev/null | awk '!seen[$0]++')

  candidate="$(command -v opencode || true)"
  if [[ -n "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  echo "ERROR: Unable to resolve an opencode executable" >&2
  exit 1
}

require_cmd jq
require_cmd curl

opencode_bin="$(resolve_opencode_bin)"

tmp_dir="$(mktemp -d /tmp/opencode-broker-session.XXXXXX)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

models_object_from_lines() {
  jq -Rn '[inputs | select(length > 0)] | map({key: ., value: {}}) | from_entries'
}

json_array_arg_from_lines() {
  jq -Rn '[inputs | select(length > 0)]'
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
              and ((.notes // "") | test("not found or your project does not have access|status\": \"NOT_FOUND\"|is not authorized to perform|forbidden:"; "i"))
            ))
          | map(.broker_model_id)
          | unique) as $blocked
          | $models[] as $model
          | select(($blocked | index($model)) == null)
          | $model
    '
}

echo "==> Reading brokered bindings for OpenCode session"

bedrock_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$bedrock_instance")"
vertex_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$vertex_instance")"
gemini_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$gemini_instance")"
azure_binding="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" "$app_name" "$azure_instance")"
foundry_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$app_name" "$foundry_instance")"

aws_access_key_id="$(printf '%s' "$bedrock_json" | jq -r '.credential.inline.access_key_id')"
aws_secret_access_key="$(printf '%s' "$bedrock_json" | jq -r '.credential.inline.secret_access_key')"
aws_region="$(printf '%s' "$bedrock_json" | jq -r '.endpoint.region')"
mapfile -t bedrock_models < <(printf '%s' "$bedrock_json" | jq -r '.grant.allowed_models[]')

vertex_project="$(printf '%s' "$vertex_json" | jq -r '.credential.inline.credentials_json | fromjson | .project_id')"
vertex_region="$(printf '%s' "$vertex_json" | jq -r '.endpoint.region')"
vertex_credentials_file="${tmp_dir}/vertex-service-account.json"
printf '%s' "$(printf '%s' "$vertex_json" | jq -r '.credential.inline.credentials_json')" > "$vertex_credentials_file"
mapfile -t vertex_models < <(printf '%s' "$vertex_json" | jq -r '.grant.allowed_models[]')

validation_report="$(latest_validation_report || true)"
if [[ -z "${OPENCODE_INCLUDE_UNVALIDATED_MODELS:-}" ]]; then
  mapfile -t bedrock_models < <(filter_accessible_models_from_report "aws_bedrock_identity" "$validation_report" "${bedrock_models[@]}")
  mapfile -t vertex_models < <(filter_accessible_models_from_report "google_vertex_identity" "$validation_report" "${vertex_models[@]}")
  mapfile -t vertex_models < <(printf '%s\n' "${vertex_models[@]}" | rg -vx 'claude-opus-4-6|claude-sonnet-4-6')
fi

gemini_api_key="$(printf '%s' "$gemini_json" | jq -r '.credential.inline.api_key')"
gemini_models_json="$(curl -fsS "https://generativelanguage.googleapis.com/v1beta/models?key=${gemini_api_key}")"
mapfile -t gemini_models < <(printf '%s' "$gemini_models_json" | jq -r '.models[] | select(((.supportedGenerationMethods // []) | index("generateContent")) != null) | select(((.outputTokenLimit // 0) > 0) or ((.supportedActions // []) | length >= 0)) | .name | sub("^models/"; "")')

azure_api_key="$(printf '%s' "$azure_binding" | jq -r '.credentials.api_key')"
azure_endpoint="$(printf '%s' "$azure_binding" | jq -r '.credentials.endpoint')"
mapfile -t azure_deployments < <(printf '%s' "$azure_binding" | jq -r '.credentials.deployments | fromjson | .[].name')

foundry_api_key="$(printf '%s' "$foundry_json" | jq -r '.credential.inline.api_key')"
foundry_endpoint="$(printf '%s' "$foundry_json" | jq -r '.endpoint.base_url')"
foundry_deployment="$(printf '%s' "$foundry_json" | jq -r '.credential.inline.deployment_name')"
mapfile -t foundry_allowed_models < <(printf '%s' "$foundry_json" | jq -r '.grant.allowed_models[]')

gemini_models_object="$(printf '%s\n' "${gemini_models[@]}" | models_object_from_lines)"
bedrock_models_object="$(printf '%s\n' "${bedrock_models[@]}" | models_object_from_lines)"
vertex_models_object="$(printf '%s\n' "${vertex_models[@]}" | models_object_from_lines)"
azure_models_object="$(printf '%s\n' "${azure_deployments[@]}" | models_object_from_lines)"
foundry_models_object="$(printf '%s\n' "$foundry_deployment" | models_object_from_lines)"

enabled_providers=(
  "sandbox-bedrock"
  "sandbox-vertex"
  "sandbox-gemini"
  "sandbox-azure-openai"
)

include_foundry_provider=1
if printf '%s\n' "${foundry_allowed_models[@]}" | rg -qi '(^|[[:punct:]])embedding([[:punct:]]|$)|^text-embedding'; then
  include_foundry_provider=0
fi

if [[ "$include_foundry_provider" -eq 1 ]]; then
  enabled_providers+=("sandbox-foundry")
fi

enabled_providers_json="$(printf '%s\n' "${enabled_providers[@]}" | json_array_arg_from_lines)"

config_file="${tmp_dir}/opencode-brokers.json"

jq -n \
  --arg aws_region "$aws_region" \
  --arg default_model "sandbox-azure-openai/gpt-5-4-mini" \
  --arg small_model "sandbox-gemini/gemini-2.5-flash" \
  --arg aws_access_key_id "$aws_access_key_id" \
  --arg aws_secret_access_key "$aws_secret_access_key" \
  --arg gemini_api_key "$gemini_api_key" \
  --arg vertex_project "$vertex_project" \
  --arg vertex_region "$vertex_region" \
  --argjson vertex_credentials_json "$(printf '%s' "$vertex_json" | jq -c '.credential.inline.credentials_json | fromjson')" \
  --arg azure_base_url "${azure_endpoint%/}/openai/v1" \
  --arg azure_api_key "$azure_api_key" \
  --arg foundry_base_url "${foundry_endpoint%/}/openai/v1" \
  --arg foundry_api_key "$foundry_api_key" \
  --argjson enabled_providers "$enabled_providers_json" \
  --argjson bedrock_models "$bedrock_models_object" \
  --argjson gemini_models "$gemini_models_object" \
  --argjson vertex_models "$vertex_models_object" \
  --argjson azure_models "$azure_models_object" \
  --argjson foundry_models "$foundry_models_object" \
  '{
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
  }' > "$config_file"

echo "==> Launching OpenCode with broker-backed providers"
echo "    default model: sandbox-azure-openai/gpt-5-4-mini"
if [[ "$include_foundry_provider" -eq 0 ]]; then
  echo "    omitting sandbox-foundry: current binding exposes embedding-only deployment(s)"
fi

unset AWS_PROFILE AWS_SESSION_TOKEN AWS_SECURITY_TOKEN AWS_BEARER_TOKEN_BEDROCK
export AWS_ACCESS_KEY_ID="$aws_access_key_id"
export AWS_SECRET_ACCESS_KEY="$aws_secret_access_key"
export AWS_REGION="$aws_region"
export GOOGLE_APPLICATION_CREDENTIALS="$vertex_credentials_file"
export GOOGLE_CLOUD_PROJECT="$vertex_project"
export VERTEX_LOCATION="$vertex_region"
export OPENCODE_CONFIG="$config_file"

exec "$opencode_bin" "$@"