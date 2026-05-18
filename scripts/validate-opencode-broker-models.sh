#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/validate-opencode-broker-models.sh [options]

Validates the OpenCode provider/model surface exposed by the live brokered AI
service instances in the current Cloud Foundry space.

Options:
  --provider <aws|vertex|gemini|azure|foundry|all>  Which provider slice(s) to validate. Default: all
  --output-dir <path>                               Output directory for JSON reports. Default: .cache/opencode-validations
  --prompt <text>                                   Prompt to send for run validations. Default: Reply with OK only.
  --help                                            Show this message.

The script reuses the currently validated sandbox instances:
  verify-bedrock-0505
  verify-vertex-0505
  verify-gemini-0505b
  verify-openai-eastus2-0511095227
  verify-foundry-0505c
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/model-catalog-common.sh
source "${SCRIPT_DIR}/lib/model-catalog-common.sh"

provider="all"
output_dir="${REPO_ROOT}/.cache/opencode-validations"
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
require_cmd opencode
require_cmd curl

mkdir -p "$output_dir"

generated_at="$(timestamp_utc)"
slug="$(printf '%s' "$generated_at" | tr ':TZ' '--' | tr -s '-')"
report_ndjson="${output_dir}/opencode-broker-validation-${slug}.ndjson"
report_json="${output_dir}/opencode-broker-validation-${slug}.json"

tmp_dir="$(mktemp -d /tmp/opencode-broker-validate.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

touch "$report_ndjson"

opencode_version="$(opencode --version 2>/dev/null || echo unknown)"

models_object_from_lines() {
  jq -Rn '[inputs | select(length > 0)] | map({key: ., value: {}}) | from_entries'
}

append_result() {
  local provider_family="$1"
  local broker_instance="$2"
  local opencode_provider="$3"
  local broker_model_id="$4"
  local opencode_model_id="$5"
  local backing_model_id="$6"
  local validation_mode="$7"
  local list_status="$8"
  local run_status="$9"
  local exit_code="${10}"
  local notes="${11}"

  jq -n \
    --arg provider_family "$provider_family" \
    --arg broker_instance "$broker_instance" \
    --arg opencode_provider "$opencode_provider" \
    --arg broker_model_id "$broker_model_id" \
    --arg opencode_model_id "$opencode_model_id" \
    --arg backing_model_id "$backing_model_id" \
    --arg validation_mode "$validation_mode" \
    --arg list_status "$list_status" \
    --arg run_status "$run_status" \
    --arg generated_at "$generated_at" \
    --arg notes "$notes" \
    --argjson exit_code "$exit_code" \
    '{
      generated_at: $generated_at,
      provider_family: $provider_family,
      broker_instance: $broker_instance,
      opencode_provider: $opencode_provider,
      broker_model_id: $broker_model_id,
      opencode_model_id: $opencode_model_id,
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

  if rg -aqi 'error:|forbidden:|not authorized|unable to submit request|was not found or your project does not have access' "$output_file"; then
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
  local model

  while IFS= read -r model; do
    [[ -n "$model" ]] || continue
    lookup_ref["$model"]=1
  done < "$input_file"
}

validate_bedrock() {
  local instance="verify-bedrock-0505"
  local normalized access_key secret_key region config_file listed_file output_file run_status exit_code notes
  local -a models=()
  local -A listed_lookup=()
  local model opencode_model

  echo "==> Validating AWS Bedrock models via OpenCode"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  access_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.access_key_id')"
  secret_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.secret_access_key')"
  region="$(printf '%s' "$normalized" | jq -r '.endpoint.region')"
  mapfile -t models < <(printf '%s' "$normalized" | jq -r '.grant.allowed_models[]')

  config_file="${tmp_dir}/bedrock.json"
  jq -n \
    --arg region "$region" \
    '{
      "$schema": "https://opencode.ai/config.json",
      enabled_providers: ["amazon-bedrock"],
      provider: {
        "amazon-bedrock": {
          options: {
            region: $region
          }
        }
      }
    }' > "$config_file"

  listed_file="${tmp_dir}/bedrock-models.txt"
  (
    export AWS_ACCESS_KEY_ID="$access_key"
    export AWS_SECRET_ACCESS_KEY="$secret_key"
    export AWS_REGION="$region"
    export OPENCODE_CONFIG="$config_file"
    opencode models amazon-bedrock > "$listed_file"
  )

  load_listed_lookup "$listed_file" listed_lookup

  for model in "${models[@]}"; do
    opencode_model="amazon-bedrock/${model}"
    if [[ -z "${listed_lookup[$opencode_model]:-}" ]]; then
      append_result "aws_bedrock_identity" "$instance" "amazon-bedrock" "$model" "$opencode_model" "$model" "run" "missing" "not-run" 0 "Model not listed by opencode models amazon-bedrock"
      continue
    fi

    output_file="${tmp_dir}/bedrock-$(slugify "$model").txt"
    exit_code=0
    (
      export AWS_ACCESS_KEY_ID="$access_key"
      export AWS_SECRET_ACCESS_KEY="$secret_key"
      export AWS_REGION="$region"
      export OPENCODE_CONFIG="$config_file"
      opencode run --model "$opencode_model" "$prompt" > "$output_file" 2>&1
    ) || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "aws_bedrock_identity" "$instance" "amazon-bedrock" "$model" "$opencode_model" "$model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_vertex() {
  local instance="verify-vertex-0505"
  local normalized credentials_json project_id region creds_file listed_file output_file run_status exit_code notes
  local -a models=()
  local -A listed_lookup=()
  local model opencode_model

  echo "==> Validating GCP Vertex AI models via OpenCode"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  credentials_json="$(printf '%s' "$normalized" | jq -r '.credential.inline.credentials_json')"
  project_id="$(printf '%s' "$normalized" | jq -r '.credential.inline.credentials_json | fromjson | .project_id')"
  region="$(printf '%s' "$normalized" | jq -r '.endpoint.region')"
  mapfile -t models < <(printf '%s' "$normalized" | jq -r '.grant.allowed_models[]')

  creds_file="${tmp_dir}/vertex-creds.json"
  printf '%s' "$credentials_json" > "$creds_file"

  listed_file="${tmp_dir}/vertex-models.txt"
  (
    export GOOGLE_APPLICATION_CREDENTIALS="$creds_file"
    export GOOGLE_CLOUD_PROJECT="$project_id"
    export VERTEX_LOCATION="$region"
    opencode models google-vertex > "$listed_file"
  )

  load_listed_lookup "$listed_file" listed_lookup

  for model in "${models[@]}"; do
    opencode_model="google-vertex/${model}"
    if [[ -z "${listed_lookup[$opencode_model]:-}" ]]; then
      append_result "google_vertex_identity" "$instance" "google-vertex" "$model" "$opencode_model" "$model" "run" "missing" "not-run" 0 "Model not listed by opencode models google-vertex"
      continue
    fi

    output_file="${tmp_dir}/vertex-$(slugify "$model").txt"
    exit_code=0
    (
      export GOOGLE_APPLICATION_CREDENTIALS="$creds_file"
      export GOOGLE_CLOUD_PROJECT="$project_id"
      export VERTEX_LOCATION="$region"
      opencode run --model "$opencode_model" "$prompt" > "$output_file" 2>&1
    ) || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "google_vertex_identity" "$instance" "google-vertex" "$model" "$opencode_model" "$model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_gemini() {
  local instance="verify-gemini-0505b"
  local normalized api_key base_url raw_models models_object config_file listed_file output_file run_status exit_code notes
  local -a models=()
  local -A listed_lookup=()
  local model opencode_model

  echo "==> Validating GCP Gemini API models via OpenCode"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  api_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.api_key')"
  base_url="$(printf '%s' "$normalized" | jq -r '.endpoint.base_url')"
  raw_models="$(curl -fsS "${base_url}/v1beta/models?key=${api_key}")"
  mapfile -t models < <(printf '%s' "$raw_models" | jq -r '.models[] | select(((.supportedGenerationMethods // []) | index("generateContent")) != null) | .name | sub("^models/"; "")')

  models_object="$(printf '%s\n' "${models[@]}" | models_object_from_lines)"
  config_file="${tmp_dir}/gemini.json"
  jq -n \
    --arg provider_id "sandbox-gemini" \
    --arg npm "@ai-sdk/google" \
    --arg name "Sandbox Gemini API" \
    --arg apiKey "$api_key" \
    --argjson models "$models_object" \
    '{
      "$schema": "https://opencode.ai/config.json",
      provider: {
        ($provider_id): {
          npm: $npm,
          name: $name,
          options: {
            apiKey: $apiKey
          },
          models: $models
        }
      },
      enabled_providers: [$provider_id]
    }' > "$config_file"

  listed_file="${tmp_dir}/gemini-models.txt"
  OPENCODE_CONFIG="$config_file" opencode models sandbox-gemini > "$listed_file"
  load_listed_lookup "$listed_file" listed_lookup

  for model in "${models[@]}"; do
    opencode_model="sandbox-gemini/${model}"
    if [[ -z "${listed_lookup[$opencode_model]:-}" ]]; then
      append_result "google_gemini_key" "$instance" "sandbox-gemini" "$model" "$opencode_model" "$model" "run" "missing" "not-run" 0 "Model not listed by opencode models sandbox-gemini"
      continue
    fi

    output_file="${tmp_dir}/gemini-$(slugify "$model").txt"
    exit_code=0
    OPENCODE_CONFIG="$config_file" opencode run --model "$opencode_model" "$prompt" > "$output_file" 2>&1 || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "google_gemini_key" "$instance" "sandbox-gemini" "$model" "$opencode_model" "$model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_azure() {
  local instance="verify-openai-eastus2-0511095227"
  local binding api_key endpoint deployments_json models_object config_file listed_file output_file run_status exit_code notes
  local -a deployment_names=()
  local -A listed_lookup=() backing_lookup=()
  local deployment_name opencode_model backing_model

  echo "==> Validating Azure OpenAI deployments via OpenCode"
  binding="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" scratch-app "$instance")"
  api_key="$(printf '%s' "$binding" | jq -r '.credentials.api_key')"
  endpoint="$(printf '%s' "$binding" | jq -r '.credentials.endpoint')"
  deployments_json="$(printf '%s' "$binding" | jq -r '.credentials.deployments | fromjson')"
  mapfile -t deployment_names < <(printf '%s' "$deployments_json" | jq -r '.[].name')
  while IFS=$'\t' read -r deployment_name backing_model; do
    backing_lookup["$deployment_name"]="$backing_model"
  done < <(printf '%s' "$deployments_json" | jq -r '.[] | [.name, .model] | @tsv')

  models_object="$(printf '%s\n' "${deployment_names[@]}" | models_object_from_lines)"
  config_file="${tmp_dir}/azure.json"
  jq -n \
    --arg provider_id "sandbox-azure-openai" \
    --arg npm "@ai-sdk/openai" \
    --arg name "Sandbox Azure OpenAI" \
    --arg baseURL "${endpoint%/}/openai/v1" \
    --arg apiKey "$api_key" \
    --argjson models "$models_object" \
    '{
      "$schema": "https://opencode.ai/config.json",
      provider: {
        ($provider_id): {
          npm: $npm,
          name: $name,
          options: {
            baseURL: $baseURL,
            apiKey: $apiKey
          },
          models: $models
        }
      },
      enabled_providers: [$provider_id]
    }' > "$config_file"

  listed_file="${tmp_dir}/azure-models.txt"
  OPENCODE_CONFIG="$config_file" opencode models sandbox-azure-openai > "$listed_file"
  load_listed_lookup "$listed_file" listed_lookup

  for deployment_name in "${deployment_names[@]}"; do
    opencode_model="sandbox-azure-openai/${deployment_name}"
    backing_model="${backing_lookup[$deployment_name]:-$deployment_name}"
    if [[ -z "${listed_lookup[$opencode_model]:-}" ]]; then
      append_result "azure_openai_key" "$instance" "sandbox-azure-openai" "$deployment_name" "$opencode_model" "$backing_model" "run" "missing" "not-run" 0 "Deployment not listed by opencode models sandbox-azure-openai"
      continue
    fi

    output_file="${tmp_dir}/azure-$(slugify "$deployment_name").txt"
    exit_code=0
    OPENCODE_CONFIG="$config_file" opencode run --model "$opencode_model" "$prompt" > "$output_file" 2>&1 || exit_code=$?
    run_status="$(classify_run_status "$exit_code" "$output_file")"
    notes="$(tail -n 20 "$output_file")"
    append_result "azure_openai_key" "$instance" "sandbox-azure-openai" "$deployment_name" "$opencode_model" "$backing_model" "run" "listed" "$run_status" "$exit_code" "$notes"
  done
}

validate_foundry() {
  local instance="verify-foundry-0505c"
  local normalized api_key endpoint deployment_name models_object config_file listed_file output_file run_status exit_code notes opencode_model
  local -A listed_lookup=()

  echo "==> Validating Azure Foundry preview deployment via OpenCode"
  normalized="$(bash "${SCRIPT_DIR}/local-agent-vcap.sh" --normalized scratch-app "$instance")"
  api_key="$(printf '%s' "$normalized" | jq -r '.credential.inline.api_key')"
  endpoint="$(printf '%s' "$normalized" | jq -r '.endpoint.base_url')"
  deployment_name="$(printf '%s' "$normalized" | jq -r '.credential.inline.deployment_name')"
  models_object="$(printf '%s\n' "$deployment_name" | models_object_from_lines)"

  config_file="${tmp_dir}/foundry.json"
  jq -n \
    --arg provider_id "sandbox-foundry" \
    --arg npm "@ai-sdk/openai" \
    --arg name "Sandbox Foundry Preview" \
    --arg baseURL "${endpoint%/}/openai/v1" \
    --arg apiKey "$api_key" \
    --argjson models "$models_object" \
    '{
      "$schema": "https://opencode.ai/config.json",
      provider: {
        ($provider_id): {
          npm: $npm,
          name: $name,
          options: {
            baseURL: $baseURL,
            apiKey: $apiKey
          },
          models: $models
        }
      },
      enabled_providers: [$provider_id]
    }' > "$config_file"

  listed_file="${tmp_dir}/foundry-models.txt"
  OPENCODE_CONFIG="$config_file" opencode models sandbox-foundry > "$listed_file"
  load_listed_lookup "$listed_file" listed_lookup

  opencode_model="sandbox-foundry/${deployment_name}"
  if [[ -z "${listed_lookup[$opencode_model]:-}" ]]; then
    append_result "azure_foundry_identity" "$instance" "sandbox-foundry" "$deployment_name" "$opencode_model" "$deployment_name" "run" "missing" "not-run" 0 "Deployment not listed by opencode models sandbox-foundry"
    return 0
  fi

  output_file="${tmp_dir}/foundry-$(slugify "$deployment_name").txt"
  exit_code=0
  OPENCODE_CONFIG="$config_file" opencode run --model "$opencode_model" "$prompt" > "$output_file" 2>&1 || exit_code=$?
  run_status="$(classify_run_status "$exit_code" "$output_file")"
  notes="$(tail -n 20 "$output_file")"
  append_result "azure_foundry_identity" "$instance" "sandbox-foundry" "$deployment_name" "$opencode_model" "$deployment_name" "run" "listed" "$run_status" "$exit_code" "$notes"
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

OPENCODE_VERSION="$opencode_version" jq -s \
  --arg generated_at "$generated_at" \
  '{
    generated_at: $generated_at,
    opencode_version: env.OPENCODE_VERSION,
    results: .,
    summary: {
      total: length,
      passed: ([.[] | select(.run_status == "passed")] | length),
      failed: ([.[] | select(.run_status == "failed")] | length),
      unsupported: ([.[] | select(.run_status == "unsupported")] | length),
      not_run: ([.[] | select(.run_status == "not-run")] | length),
      missing_from_opencode: ([.[] | select(.list_status != "listed")] | length)
    },
    by_provider: (
      group_by(.provider_family) | map({
        provider_family: .[0].provider_family,
        total: length,
        passed: ([.[] | select(.run_status == "passed")] | length),
        failed: ([.[] | select(.run_status == "failed")] | length),
        unsupported: ([.[] | select(.run_status == "unsupported")] | length),
        not_run: ([.[] | select(.run_status == "not-run")] | length),
        missing_from_opencode: ([.[] | select(.list_status != "listed")] | length)
      })
    )
  }' "$report_ndjson" > "$report_json"

echo "Wrote OpenCode validation report to $report_json"
jq '.summary, .by_provider' "$report_json"