#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/validate-pi-broker-models.sh [options]

Validates live brokered AI service instances with Pi using only temporary Pi
configuration. The script does not modify ~/.pi/agent or OpenCode config.

Options:
  --provider <aws|vertex|gemini|azure|foundry|all>  Provider slice(s) to validate. Default: all
  --output-dir <path>                               Output directory for JSON reports. Default: .cache/pi-validations
  --prompt <text>                                   Prompt to send. Default: Reply with OK only.
  --help                                            Show this message.

Instance overrides:
  BEDROCK_INSTANCE
  VERTEX_INSTANCE
  GEMINI_INSTANCE
  AZURE_OPENAI_INSTANCE
  FOUNDRY_INSTANCE
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/model-catalog-common.sh
source "${SCRIPT_DIR}/lib/model-catalog-common.sh"

provider="all"
output_dir="${REPO_ROOT}/.cache/pi-validations"
prompt="Reply with OK only."

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      provider="$2"
      shift 2
      ;;
    --output-dir)
      output_dir="$2"
      shift 2
      ;;
    --prompt)
      prompt="$2"
      shift 2
      ;;
    --)
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$provider" in
  aws|vertex|gemini|azure|foundry|all)
    ;;
  *)
    echo "ERROR: --provider must be one of aws, vertex, gemini, azure, foundry, all." >&2
    exit 1
    ;;
esac

require_cmd jq
require_cmd cf

PI_BIN="${PI_BIN:-pi}"
if ! command -v "$PI_BIN" >/dev/null 2>&1; then
  echo "ERROR: pi command not found. Install with: npm install -g @earendil-works/pi-coding-agent" >&2
  exit 1
fi

mkdir -p "$output_dir"

generated_at="$(timestamp_utc)"
slug="$(printf '%s' "$generated_at" | tr ':TZ' '--' | tr -s '-')"
report_ndjson="${output_dir}/pi-broker-validation-${slug}.ndjson"
report_json="${output_dir}/pi-broker-validation-${slug}.json"

tmp_dir="$(mktemp -d /tmp/pi-broker-validate.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

touch "$report_ndjson"

pi_version="$($PI_BIN --version 2>/dev/null || echo unknown)"

model_json_array() {
  jq -Rn '[inputs | select(length > 0) | {id: ., name: ., reasoning: false, input: ["text"], contextWindow: 128000, maxTokens: 4096, cost: {input: 0, output: 0, cacheRead: 0, cacheWrite: 0}}]'
}

required_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    echo "ERROR: ${name} must be set to a Cloud Foundry service instance name." >&2
    exit 1
  fi
}

append_result() {
  local provider_family="$1"
  local broker_instance="$2"
  local pi_provider="$3"
  local broker_model_id="$4"
  local pi_model_id="$5"
  local backing_model_id="$6"
  local validation_mode="$7"
  local list_status="$8"
  local run_status="$9"
  local exit_code="${10}"
  local notes="${11}"

  jq -n \
    --arg provider_family "$provider_family" \
    --arg broker_instance "$broker_instance" \
    --arg pi_provider "$pi_provider" \
    --arg broker_model_id "$broker_model_id" \
    --arg pi_model_id "$pi_model_id" \
    --arg backing_model_id "$backing_model_id" \
    --arg validation_mode "$validation_mode" \
    --arg list_status "$list_status" \
    --arg run_status "$run_status" \
    --arg generated_at "$generated_at" \
    --arg pi_version "$pi_version" \
    --arg notes "$notes" \
    --argjson exit_code "$exit_code" \
    '{
      generated_at: $generated_at,
      validator: "pi",
      pi_version: $pi_version,
      provider_family: $provider_family,
      broker_instance: $broker_instance,
      pi_provider: $pi_provider,
      broker_model_id: $broker_model_id,
      pi_model_id: $pi_model_id,
      backing_model_id: $backing_model_id,
      validation_mode: $validation_mode,
      list_status: $list_status,
      run_status: $run_status,
      exit_code: $exit_code,
      notes: $notes
    }' >> "$report_ndjson"
}

classify_run_status() {
  local exit_code="$1"
  local output_file="$2"

  if rg -qi 'unsupported|not supported|embedding' "$output_file"; then
    printf 'unsupported'
    return 0
  fi

  if rg -aqi 'error:|forbidden:|not authorized|unable to submit request|was not found or your project does not have access|No models available|InvalidClientTokenId|AccessDenied|UnrecognizedClientException' "$output_file"; then
    printf 'failed'
    return 0
  fi

  if [[ "$exit_code" -eq 0 ]]; then
    printf 'passed'
    return 0
  fi

  printf 'failed'
}

load_listed_lookup() {
  local input_file="$1"
  local -n lookup_ref="$2"
  local first second rest

  while read -r first second rest; do
    [[ -n "${first:-}" ]] || continue
    [[ "$first" == "provider" ]] && continue
    [[ "$first" == "No" && "$second" == "models" ]] && continue

    if [[ "$first" == */* ]]; then
      lookup_ref["$first"]=1
    elif [[ -n "${second:-}" ]]; then
      lookup_ref["${first}/${second}"]=1
    fi
  done < "$input_file"
}

prepare_pi_dir() {
  local name="$1"
  local pi_dir="${tmp_dir}/${name}/pi"
  mkdir -p "$pi_dir"
  printf '%s' "$pi_dir"
}

run_pi_list() {
  local pi_dir="$1"
  local provider_id="$2"
  local output_file="$3"
  shift 3
  PI_CODING_AGENT_DIR="$pi_dir" "$PI_BIN" --no-extensions --no-skills --no-context-files --no-session --list-models "$provider_id" "$@" > "$output_file"
}

run_pi_prompt() {
  local pi_dir="$1"
  local model_id="$2"
  local output_file="$3"
  shift 3
  PI_CODING_AGENT_DIR="$pi_dir" "$PI_BIN" --no-extensions --no-skills --no-context-files --no-session --print --model "$model_id" "$@" "$prompt" > "$output_file" 2>&1
}

write_models_json() {
  local pi_dir="$1"
  local provider_id="$2"
  local base_url="$3"
  local api_key_ref="$4"
  local api_type="$5"
  local models_json="$6"
  local compat_json="${7:-null}"

  jq -n \
    --arg provider_id "$provider_id" \
    --arg base_url "$base_url" \
    --arg api_key_ref "$api_key_ref" \
    --arg api_type "$api_type" \
    --argjson models "$models_json" \
    --argjson compat "$compat_json" \
    '{providers: {($provider_id): ({baseUrl: $base_url, apiKey: $api_key_ref, api: $api_type, models: $models} + (if $compat == null then {} else {compat: $compat} end))}}' \
    > "${pi_dir}/models.json"
}

validate_bedrock() {
  required_env BEDROCK_INSTANCE
  local instance="$BEDROCK_INSTANCE"
  local normalized access_key secret_key region pi_dir listed_file output_file run_status exit_code notes
  local -a models=()
  local -A listed_lookup=()
  local model pi_model

  echo "==> Validating AWS Bedrock models via Pi"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  access_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.access_key_id')"
  secret_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.secret_access_key')"
  region="$(printf '%s' "$normalized" | jq -r '.endpoint.region // "us-east-1"')"
  mapfile -t models < <(printf '%s' "$normalized" | jq -r '.grant.allowed_models[]')

  pi_dir="$(prepare_pi_dir bedrock)"
  listed_file="${tmp_dir}/bedrock-models.txt"
  (
    unset AWS_PROFILE AWS_SESSION_TOKEN AWS_SECURITY_TOKEN AWS_BEARER_TOKEN_BEDROCK
    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret_key"
    export AWS_REGION="$region"
    run_pi_list "$pi_dir" amazon-bedrock "$listed_file" --provider amazon-bedrock
  )
  load_listed_lookup "$listed_file" listed_lookup

  for model in "${models[@]}"; do
    pi_model="amazon-bedrock/${model}"
    if [[ -z "${listed_lookup[$pi_model]:-}" ]]; then
      append_result "aws_bedrock_identity" "$instance" "amazon-bedrock" "$model" "$pi_model" "$model" "run" "missing" "not-run" 0 "Model not listed by pi --list-models amazon-bedrock"
      continue
    fi

    output_file="${tmp_dir}/bedrock-$(slugify "$model").txt"
    exit_code=0
    (
      unset AWS_PROFILE AWS_SESSION_TOKEN AWS_SECURITY_TOKEN AWS_BEARER_TOKEN_BEDROCK
      export AWS_ACCESS_KEY_ID="$access_key"
      export AWS_SECRET_ACCESS_KEY="$secret_key"
      export AWS_REGION="$region"
      run_pi_prompt "$pi_dir" "$pi_model" "$output_file" --provider amazon-bedrock
    ) || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "aws_bedrock_identity" "$instance" "amazon-bedrock" "$model" "$pi_model" "$model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_vertex() {
  required_env VERTEX_INSTANCE
  local instance="$VERTEX_INSTANCE"
  local normalized credentials_json project_id region creds_file pi_dir listed_file output_file run_status exit_code notes
  local -a models=()
  local -A listed_lookup=()
  local model pi_model

  echo "==> Validating GCP Vertex AI models via Pi"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  credentials_json="$(printf '%s' "$normalized" | jq -r '.credential.inline.credentials_json')"
  project_id="$(printf '%s' "$credentials_json" | jq -r '.project_id')"
  region="$(printf '%s' "$normalized" | jq -r '.endpoint.region')"
  mapfile -t models < <(printf '%s' "$normalized" | jq -r '.grant.allowed_models[]')

  pi_dir="$(prepare_pi_dir vertex)"
  creds_file="${tmp_dir}/vertex-creds.json"
  printf '%s' "$credentials_json" > "$creds_file"

  listed_file="${tmp_dir}/vertex-models.txt"
  (
    export GOOGLE_APPLICATION_CREDENTIALS="$creds_file"
    export GOOGLE_CLOUD_PROJECT="$project_id"
    export GOOGLE_CLOUD_LOCATION="$region"
    run_pi_list "$pi_dir" google-vertex "$listed_file" --provider google-vertex
  )
  load_listed_lookup "$listed_file" listed_lookup

  for model in "${models[@]}"; do
    pi_model="google-vertex/${model}"
    if [[ -z "${listed_lookup[$pi_model]:-}" ]]; then
      append_result "google_vertex_identity" "$instance" "google-vertex" "$model" "$pi_model" "$model" "run" "missing" "not-run" 0 "Model not listed by pi --list-models google-vertex"
      continue
    fi

    output_file="${tmp_dir}/vertex-$(slugify "$model").txt"
    exit_code=0
    (
      export GOOGLE_APPLICATION_CREDENTIALS="$creds_file"
      export GOOGLE_CLOUD_PROJECT="$project_id"
      export GOOGLE_CLOUD_LOCATION="$region"
      run_pi_prompt "$pi_dir" "$pi_model" "$output_file" --provider google-vertex
    ) || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "google_vertex_identity" "$instance" "google-vertex" "$model" "$pi_model" "$model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_gemini() {
  required_env GEMINI_INSTANCE
  local instance="$GEMINI_INSTANCE"
  local normalized api_key base_url raw_models models_json pi_dir listed_file output_file run_status exit_code notes
  local -a models=()
  local -A listed_lookup=()
  local model pi_model

  echo "==> Validating GCP Gemini API models via Pi"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  api_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.api_key')"
  base_url="$(printf '%s' "$normalized" | jq -r '.endpoint.base_url')"
  raw_models="$(curl -fsS "${base_url}/v1beta/models?key=${api_key}")"
  mapfile -t models < <(printf '%s' "$raw_models" | jq -r '.models[] | select(((.supportedGenerationMethods // []) | index("generateContent")) != null) | .name | sub("^models/"; "")')
  models_json="$(printf '%s\n' "${models[@]}" | model_json_array)"

  pi_dir="$(prepare_pi_dir gemini)"
  write_models_json "$pi_dir" sandbox-gemini "${base_url%/}/v1beta" '$GEMINI_API_KEY' google-generative-ai "$models_json"

  listed_file="${tmp_dir}/gemini-models.txt"
  GEMINI_API_KEY="$api_key" run_pi_list "$pi_dir" sandbox-gemini "$listed_file" --provider sandbox-gemini
  load_listed_lookup "$listed_file" listed_lookup

  for model in "${models[@]}"; do
    pi_model="sandbox-gemini/${model}"
    if [[ -z "${listed_lookup[$pi_model]:-}" ]]; then
      append_result "google_gemini_key" "$instance" "sandbox-gemini" "$model" "$pi_model" "$model" "run" "missing" "not-run" 0 "Model not listed by pi --list-models sandbox-gemini"
      continue
    fi

    output_file="${tmp_dir}/gemini-$(slugify "$model").txt"
    exit_code=0
    GEMINI_API_KEY="$api_key" run_pi_prompt "$pi_dir" "$pi_model" "$output_file" --provider sandbox-gemini || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "google_gemini_key" "$instance" "sandbox-gemini" "$model" "$pi_model" "$model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_azure() {
  required_env AZURE_OPENAI_INSTANCE
  local instance="$AZURE_OPENAI_INSTANCE"
  local binding api_key endpoint deployments_json models_json pi_dir listed_file output_file run_status exit_code notes map_value
  local -a deployment_names=()
  local -A listed_lookup=() backing_lookup=()
  local deployment_name pi_model backing_model

  echo "==> Validating Azure OpenAI deployments via Pi"
  binding="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" scratch-app "$instance")"
  api_key="$(printf '%s' "$binding" | jq -r '.credentials.api_key')"
  endpoint="$(printf '%s' "$binding" | jq -r '.credentials.endpoint')"
  deployments_json="$(printf '%s' "$binding" | jq -r '.credentials.deployments | fromjson')"
  mapfile -t deployment_names < <(printf '%s' "$deployments_json" | jq -r '.[].name')
  while IFS=$'\t' read -r deployment_name backing_model; do
    backing_lookup["$deployment_name"]="$backing_model"
  done < <(printf '%s' "$deployments_json" | jq -r '.[] | [.name, .model] | @tsv')
  models_json="$(printf '%s\n' "${deployment_names[@]}" | model_json_array)"
  map_value="$(printf '%s' "$deployments_json" | jq -r '[.[] | "\(.model)=\(.name)"] | join(",")')"

  pi_dir="$(prepare_pi_dir azure)"
  write_models_json "$pi_dir" sandbox-azure-openai "${endpoint%/}/openai/v1" '$AZURE_OPENAI_API_KEY' openai-completions "$models_json" '{"supportsDeveloperRole":false,"supportsReasoningEffort":false}'

  listed_file="${tmp_dir}/azure-models.txt"
  AZURE_OPENAI_API_KEY="$api_key" AZURE_OPENAI_BASE_URL="$endpoint" AZURE_OPENAI_DEPLOYMENT_NAME_MAP="$map_value" run_pi_list "$pi_dir" sandbox-azure-openai "$listed_file" --provider sandbox-azure-openai
  load_listed_lookup "$listed_file" listed_lookup

  for deployment_name in "${deployment_names[@]}"; do
    pi_model="sandbox-azure-openai/${deployment_name}"
    backing_model="${backing_lookup[$deployment_name]:-$deployment_name}"
    if [[ -z "${listed_lookup[$pi_model]:-}" ]]; then
      append_result "azure_openai_key" "$instance" "sandbox-azure-openai" "$deployment_name" "$pi_model" "$backing_model" "run" "missing" "not-run" 0 "Deployment not listed by pi --list-models sandbox-azure-openai"
      continue
    fi

    output_file="${tmp_dir}/azure-$(slugify "$deployment_name").txt"
    exit_code=0
    AZURE_OPENAI_API_KEY="$api_key" AZURE_OPENAI_BASE_URL="$endpoint" AZURE_OPENAI_DEPLOYMENT_NAME_MAP="$map_value" run_pi_prompt "$pi_dir" "$pi_model" "$output_file" --provider sandbox-azure-openai || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "azure_openai_key" "$instance" "sandbox-azure-openai" "$deployment_name" "$pi_model" "$backing_model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_foundry() {
  required_env FOUNDRY_INSTANCE
  local instance="$FOUNDRY_INSTANCE"
  local normalized api_key endpoint deployment_name models_json pi_dir listed_file output_file run_status exit_code notes pi_model
  local -A listed_lookup=()

  echo "==> Validating Azure Foundry preview deployment via Pi"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  api_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.api_key')"
  endpoint="$(printf '%s' "$normalized" | jq -r '.endpoint.base_url')"
  deployment_name="$(printf '%s' "$normalized" | jq -r '.credential.inline.deployment_name')"
  models_json="$(printf '%s\n' "$deployment_name" | model_json_array)"

  pi_dir="$(prepare_pi_dir foundry)"
  write_models_json "$pi_dir" sandbox-foundry "${endpoint%/}/openai/v1" '$AZURE_OPENAI_API_KEY' openai-completions "$models_json" '{"supportsDeveloperRole":false,"supportsReasoningEffort":false}'

  listed_file="${tmp_dir}/foundry-models.txt"
  AZURE_OPENAI_API_KEY="$api_key" run_pi_list "$pi_dir" sandbox-foundry "$listed_file" --provider sandbox-foundry
  load_listed_lookup "$listed_file" listed_lookup

  pi_model="sandbox-foundry/${deployment_name}"
  if [[ -z "${listed_lookup[$pi_model]:-}" ]]; then
    append_result "azure_foundry_identity" "$instance" "sandbox-foundry" "$deployment_name" "$pi_model" "$deployment_name" "run" "missing" "not-run" 0 "Deployment not listed by pi --list-models sandbox-foundry"
    return
  fi

  output_file="${tmp_dir}/foundry-$(slugify "$deployment_name").txt"
  exit_code=0
  AZURE_OPENAI_API_KEY="$api_key" run_pi_prompt "$pi_dir" "$pi_model" "$output_file" --provider sandbox-foundry || exit_code=$?
  run_status="$(classify_run_status "$exit_code" "$output_file")"
  notes="$(tail -n 20 "$output_file")"
  append_result "azure_foundry_identity" "$instance" "sandbox-foundry" "$deployment_name" "$pi_model" "$deployment_name" "run" "listed" "$run_status" "$exit_code" "$notes"
}

case "$provider" in
  aws)
    validate_bedrock
    ;;
  vertex)
    validate_vertex
    ;;
  gemini)
    validate_gemini
    ;;
  azure)
    validate_azure
    ;;
  foundry)
    validate_foundry
    ;;
  all)
    validate_bedrock
    validate_vertex
    validate_gemini
    validate_azure
    validate_foundry
    ;;
esac

jq -s \
  --arg generated_at "$generated_at" \
  --arg pi_version "$pi_version" \
  '{
    generated_at: $generated_at,
    validator: "pi",
    pi_version: $pi_version,
    totals: {
      checks: length,
      listed: map(select(.list_status == "listed")) | length,
      missing: map(select(.list_status == "missing")) | length,
      passed: map(select(.run_status == "passed")) | length,
      failed: map(select(.run_status == "failed")) | length,
      unsupported: map(select(.run_status == "unsupported")) | length,
      not_run: map(select(.run_status == "not-run")) | length
    },
    results: .
  }' "$report_ndjson" > "$report_json"

echo "Wrote ${report_json}"
jq '.totals' "$report_json"
