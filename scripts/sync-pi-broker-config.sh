#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/sync-pi-broker-config.sh [options]

Updates Pi's shared config from live Cloud Service Broker AI bindings. Secrets
are written to Pi auth.json; provider/model metadata is written to models.json.
Existing files are backed up before modification.

Options:
  --pi-dir <path>     Pi config directory. Default: ~/.pi/agent
  --app <name>        CF app used for service bindings. Default: scratch-app
  --help              Show this message.

Instance overrides:
  BEDROCK_INSTANCE          Required unless --skip-bedrock is added later
  VERTEX_INSTANCE           Required unless --skip-vertex is added later
  GEMINI_INSTANCE           Required unless --skip-gemini is added later
  AZURE_OPENAI_INSTANCE     Required unless --skip-azure-openai is added later
  FOUNDRY_INSTANCE          Required unless --skip-foundry is added later

Optional validation scoping:
  PI_VALIDATION_REPORT      Path to a validate-pi-broker-models.sh JSON report.
                            When set, enabledModels is limited to passed models.

CF target:
  DEPLOY_CF_ORG and DEPLOY_CF_SPACE are optional. When both are set, the script
  retargets Cloud Foundry before reading service bindings.
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/model-catalog-common.sh
source "${SCRIPT_DIR}/lib/model-catalog-common.sh"

require_cmd jq
require_cmd cf
require_cmd node
require_cmd pi

PI_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
APP_NAME="scratch-app"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pi-dir)
      PI_DIR="$2"
      shift 2
      ;;
    --app)
      APP_NAME="$2"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

required_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: ${name} must be set to a Cloud Foundry service instance name." >&2
    exit 1
  fi
}

required_env BEDROCK_INSTANCE
required_env VERTEX_INSTANCE
required_env GEMINI_INSTANCE
required_env AZURE_OPENAI_INSTANCE
required_env FOUNDRY_INSTANCE

mkdir -p "$PI_DIR"
chmod 700 "$PI_DIR"

auth_file="${PI_DIR}/auth.json"
models_file="${PI_DIR}/models.json"
settings_file="${PI_DIR}/settings.json"
backup_suffix="$(date -u +%Y%m%dT%H%M%SZ)"

backup_if_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "${file}.${backup_suffix}.bak"
    chmod 600 "${file}.${backup_suffix}.bak"
  fi
}

normalize_binding() {
  local instance="$1"
  bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized "$APP_NAME" "$instance"
}

fetch_gemini_models() {
  local base_url="$1"
  local api_key="$2"
  curl -fsS "${base_url%/}/v1beta/models?key=${api_key}" |
    jq '[.models[] | select(((.supportedGenerationMethods // []) | index("generateContent")) != null) | .name | sub("^models/"; "") | {id: ., name: ., reasoning: false, input: ["text"], contextWindow: 128000, maxTokens: 4096, cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}}]'
}

model_array_from_lines() {
  jq -Rn '[inputs | select(length > 0) | {id: ., name: ., reasoning: false, input: ["text"], contextWindow: 128000, maxTokens: 4096, cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}}]'
}

models_from_pi_table() {
  local provider_name="$1"
  awk -v provider="$provider_name" '
    $1 == provider {
      print $2
    }
  ' | model_array_from_lines
}

intersect_model_arrays() {
  local allowed_json="$1"
  local listed_json="$2"
  jq -n \
    --argjson allowed "$allowed_json" \
    --argjson listed "$listed_json" \
    '($listed | map(.id) | INDEX(.)) as $listed_by_id |
     [$allowed[] | select($listed_by_id[.id])]'
}

discover_bedrock_models() {
  local env_file="$1"
  local output_file="$2"
  if bash -c 'source "$1" && pi --no-extensions --no-skills --no-context-files --no-session --list-models amazon-bedrock' _ "$env_file" > "$output_file" 2>/dev/null; then
    models_from_pi_table amazon-bedrock < "$output_file"
    return 0
  fi
  return 1
}

discover_vertex_models() {
  local env_file="$1"
  local output_file="$2"
  if bash -c 'source "$1" && pi --no-extensions --no-skills --no-context-files --no-session --list-models google-vertex' _ "$env_file" > "$output_file" 2>/dev/null; then
    models_from_pi_table google-vertex < "$output_file"
    return 0
  fi
  return 1
}

work_dir="$(mktemp -d /tmp/pi-broker-sync.XXXXXX)"
trap 'rm -rf "$work_dir"' EXIT

if [[ -n "${DEPLOY_CF_ORG:-}" && -n "${DEPLOY_CF_SPACE:-}" ]]; then
  printf 'Reading broker bindings from configured Cloud Foundry target via app %s...\n' "$APP_NAME"
else
  printf 'Reading broker bindings from current Cloud Foundry target via app %s...\n' "$APP_NAME"
fi

bedrock_json="$(normalize_binding "$BEDROCK_INSTANCE")"
vertex_json="$(normalize_binding "$VERTEX_INSTANCE")"
gemini_raw_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" "$APP_NAME" "$GEMINI_INSTANCE")"
gemini_json="$(normalize_binding "$GEMINI_INSTANCE")"
azure_raw_json="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" "$APP_NAME" "$AZURE_OPENAI_INSTANCE")"
foundry_json="$(normalize_binding "$FOUNDRY_INSTANCE")"

gemini_api_key="$(printf '%s' "$gemini_raw_json" | jq -r '.credentials.api_key')"
gemini_base_url="$(printf '%s' "$gemini_json" | jq -r '.endpoint.base_url // empty')"
if [[ -z "$gemini_base_url" ]]; then
  gemini_base_url="$(printf '%s' "$gemini_raw_json" | jq -r '.credentials.api_endpoint // empty')"
fi
if [[ -z "$gemini_base_url" ]]; then
  echo "ERROR: Gemini binding did not include base_url, endpoint, or api_endpoint." >&2
  exit 1
fi
gemini_models="$(fetch_gemini_models "$gemini_base_url" "$gemini_api_key")"

bedrock_models="$(printf '%s' "$bedrock_json" | jq -r '.grant.allowed_models[]' | model_array_from_lines)"
vertex_models="$(printf '%s' "$vertex_json" | jq -r '.grant.allowed_models[]' | model_array_from_lines)"
azure_deployments="$(printf '%s' "$azure_raw_json" | jq -r '.credentials.deployments | fromjson')"
azure_models="$(printf '%s' "$azure_deployments" | jq '[.[] | {id: .name, name: (.model + " (" + .name + ")"), reasoning: false, input: ["text"], contextWindow: 128000, maxTokens: 4096, cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}}]')"
foundry_deployment="$(printf '%s' "$foundry_json" | jq -r '.credential.inline.deployment_name')"
foundry_models="$(printf '%s\n' "$foundry_deployment" | model_array_from_lines)"

vertex_creds_file="${PI_DIR}/broker-google-vertex-credentials.json"
printf '%s' "$vertex_json" | jq -r '.credential.inline.credentials_json' > "$vertex_creds_file"
chmod 600 "$vertex_creds_file"

bedrock_env_file="${PI_DIR}/broker-bedrock.env"
vertex_env_file="${PI_DIR}/broker-google-vertex.env"
gemini_auth="${work_dir}/gemini-auth.json"
azure_auth="${work_dir}/azure-auth.json"
foundry_auth="${work_dir}/foundry-auth.json"
models_patch="${work_dir}/models-patch.json"

printf '%s' "$bedrock_json" | jq -r '
  "export AWS_ACCESS_KEY_ID=\(.credential.inline.access_key_id | @sh)\n" +
  "export AWS_SECRET_ACCESS_KEY=\(.credential.inline.secret_access_key | @sh)\n" +
  "export AWS_REGION=\(.endpoint.region | @sh)\n" +
  "unset AWS_PROFILE AWS_SESSION_TOKEN AWS_SECURITY_TOKEN\n"
' > "$bedrock_env_file"
chmod 600 "$bedrock_env_file"

printf '%s' "$vertex_json" | jq -r --arg creds_file "$vertex_creds_file" '
  "export GOOGLE_APPLICATION_CREDENTIALS=\($creds_file | @sh)\n" +
  "export GOOGLE_CLOUD_PROJECT=\(.credential.inline.credentials_json | fromjson | .project_id | @sh)\n" +
  "export GOOGLE_CLOUD_LOCATION=\(.endpoint.region | @sh)\n"
' > "$vertex_env_file"
chmod 600 "$vertex_env_file"

bedrock_discovery_output="${work_dir}/bedrock-models.txt"
if discovered_models="$(discover_bedrock_models "$bedrock_env_file" "$bedrock_discovery_output")" && [[ "$(printf '%s' "$discovered_models" | jq 'length')" -gt 0 ]]; then
  bedrock_models="$(intersect_model_arrays "$bedrock_models" "$discovered_models")"
  printf '  matched AWS Bedrock broker-granted models in provider catalog: %s\n' "$(printf '%s' "$bedrock_models" | jq 'length')"
else
  printf '  warning: AWS Bedrock catalog discovery failed; using broker binding model list.\n' >&2
fi

vertex_discovery_output="${work_dir}/vertex-models.txt"
if discovered_models="$(discover_vertex_models "$vertex_env_file" "$vertex_discovery_output")" && [[ "$(printf '%s' "$discovered_models" | jq 'length')" -gt 0 ]]; then
  vertex_models="$(intersect_model_arrays "$vertex_models" "$discovered_models")"
  printf '  matched Google Vertex broker-granted models in provider catalog: %s\n' "$(printf '%s' "$vertex_models" | jq 'length')"
else
  printf '  warning: Google Vertex catalog discovery failed; using broker binding model list.\n' >&2
fi

jq -n --arg key "$gemini_api_key" '{
  "sandbox-gemini": {
    type: "api_key",
    key: $key
  }
}' > "$gemini_auth"

printf '%s' "$azure_raw_json" | jq '{
  "sandbox-azure-openai": {
    type: "api_key",
    key: .credentials.api_key,
    env: {
      AZURE_OPENAI_API_KEY: .credentials.api_key,
      AZURE_OPENAI_BASE_URL: .credentials.endpoint,
      AZURE_OPENAI_API_VERSION: (.credentials.api_version // "v1"),
      AZURE_OPENAI_DEPLOYMENT_NAME_MAP: ((.credentials.deployments | fromjson) | map(.model + "=" + .name) | join(","))
    }
  }
}' > "$azure_auth"

printf '%s' "$foundry_json" | jq '{
  "sandbox-foundry": {
    type: "api_key",
    key: .credential.inline.api_key,
    env: {
      AZURE_OPENAI_API_KEY: .credential.inline.api_key,
      AZURE_OPENAI_BASE_URL: .endpoint.base_url,
      AZURE_OPENAI_API_VERSION: (.endpoint.api_version // "v1")
    }
  }
}' > "$foundry_auth"

jq -n \
  --arg bedrock_region "$(printf '%s' "$bedrock_json" | jq -r '.endpoint.region')" \
  --arg vertex_region "$(printf '%s' "$vertex_json" | jq -r '.endpoint.region')" \
  --arg vertex_project "$(printf '%s' "$vertex_json" | jq -r '.credential.inline.credentials_json | fromjson | .project_id')" \
  --arg gemini_base_url "${gemini_base_url%/}/v1beta" \
  --arg azure_base_url "$(printf '%s' "$azure_raw_json" | jq -r '.credentials.endpoint')/openai/v1" \
  --arg foundry_base_url "$(printf '%s' "$foundry_json" | jq -r '.endpoint.base_url')/openai/v1" \
  --argjson bedrock_models "$bedrock_models" \
  --argjson vertex_models "$vertex_models" \
  --argjson gemini_models "$gemini_models" \
  --argjson azure_models "$azure_models" \
  --argjson foundry_models "$foundry_models" \
  '{
    providers: {
      "amazon-bedrock": {
        models: $bedrock_models
      },
      "google-vertex": {
        models: $vertex_models
      },
      "sandbox-gemini": {
        baseUrl: $gemini_base_url,
        api: "google-generative-ai",
        apiKey: "$GEMINI_API_KEY",
        models: $gemini_models
      },
      "sandbox-azure-openai": {
        baseUrl: $azure_base_url,
        api: "openai-completions",
        apiKey: "$AZURE_OPENAI_API_KEY",
        compat: {
          supportsDeveloperRole: false,
          supportsReasoningEffort: false
        },
        models: $azure_models
      },
      "sandbox-foundry": {
        baseUrl: $foundry_base_url,
        api: "openai-completions",
        apiKey: "$AZURE_OPENAI_API_KEY",
        compat: {
          supportsDeveloperRole: false,
          supportsReasoningEffort: false
        },
        models: $foundry_models
      }
    }
  }' > "$models_patch"

backup_if_exists "$auth_file"
backup_if_exists "$models_file"
backup_if_exists "$settings_file"

node "$SCRIPT_DIR/sync-pi-broker-config.mjs" \
  "$auth_file" \
  "$models_file" \
  "$settings_file" \
  "$models_patch" \
  "${PI_VALIDATION_REPORT:--}" \
  "$gemini_auth" \
  "$azure_auth" \
  "$foundry_auth"

chmod 600 "$auth_file" "$models_file" "$settings_file"

printf 'Updated Pi config at %s\n' "$PI_DIR"
printf '  auth.json providers: sandbox-gemini, sandbox-azure-openai, sandbox-foundry\n'
printf '  models.json providers: amazon-bedrock, google-vertex, sandbox-gemini, sandbox-azure-openai, sandbox-foundry\n'
printf '  Vertex service account file: %s\n' "$vertex_creds_file"
printf '  Vertex env file: %s\n' "$vertex_env_file"
printf '  Bedrock env file: %s\n' "$bedrock_env_file"
printf 'Run: pi --list-models sandbox-azure-openai\n'
printf 'For Bedrock and Vertex, launch Pi with env from the generated env files.\n'
