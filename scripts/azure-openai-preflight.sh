#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/azure-openai-preflight.sh \
    --location <azure-region> \
    --deployments-json '<json-array>' \
    [--resource-group <rg>] \
    [--account-name <name>] \
    [--subscription <subscription-id>] \
    [--sku-name <deployment-sku>] \
    [--probe-create]

Validates an Azure OpenAI deployment matrix against Azure CLI model metadata.

By default the script performs non-destructive checks:
  - resolves a probe OpenAI account in the requested region
  - verifies each deployment's model/version exists in Azure's model catalog
  - prints relevant capability keys such as priorityTierSkus

With --probe-create, the script also attempts the same deployment create call that
OpenTofu performs, then deletes the temporary deployment on success.
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $cmd" >&2
    exit 1
  fi
}

sanitize_name() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9-' '-'
}

probe_create_result() {
  local resource_group="$1"
  local account_name="$2"
  local deployment_name="$3"
  local model_name="$4"
  local model_version="$5"
  local sku_name="$6"
  local capacity="$7"

  local output
  if output=$(az cognitiveservices account deployment create \
    --resource-group "$resource_group" \
    --name "$account_name" \
    --deployment-name "$deployment_name" \
    --model-format OpenAI \
    --model-name "$model_name" \
    --model-version "$model_version" \
    --sku-name "$sku_name" \
    --sku-capacity "$capacity" \
    -o json 2>&1); then
    echo "CREATE_OK"
    az cognitiveservices account deployment delete \
      --resource-group "$resource_group" \
      --name "$account_name" \
      --deployment-name "$deployment_name" \
      --yes >/dev/null
    return 0
  fi

  printf '%s\n' "$output"
  return 1
}

location=""
deployments_json=""
resource_group=""
account_name=""
subscription=""
sku_name="Standard"
probe_create=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
      shift
      ;;
    --location)
      location="$2"
      shift 2
      ;;
    --deployments-json)
      deployments_json="$2"
      shift 2
      ;;
    --resource-group)
      resource_group="$2"
      shift 2
      ;;
    --account-name)
      account_name="$2"
      shift 2
      ;;
    --subscription)
      subscription="$2"
      shift 2
      ;;
    --sku-name)
      sku_name="$2"
      shift 2
      ;;
    --probe-create)
      probe_create=1
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

if [[ -z "$location" || -z "$deployments_json" ]]; then
  usage >&2
  exit 1
fi

require_cmd az
require_cmd jq

if [[ -z "$subscription" ]]; then
  subscription="$(az account show --query id -o tsv)"
fi

if [[ -z "$account_name" || -z "$resource_group" ]]; then
  discovered_account="$({ az cognitiveservices account list --subscription "$subscription" -o json || true; } | jq -r --arg location "$location" '
    map(select(.kind == "OpenAI" and .location == $location and .properties.provisioningState == "Succeeded"))
    | first
    | if . == null then empty else [.name, .resourceGroup] | @tsv end
  ')"

  if [[ -z "$discovered_account" ]]; then
    echo "ERROR: No succeeded Azure OpenAI account found in subscription $subscription and region $location." >&2
    echo "       Pass --account-name and --resource-group to use an explicit probe account." >&2
    exit 1
  fi

  if [[ -z "$account_name" ]]; then
    account_name="${discovered_account%%$'\t'*}"
  fi
  if [[ -z "$resource_group" ]]; then
    resource_group="${discovered_account#*$'\t'}"
  fi
fi

echo "==> Using probe account: $account_name (resource group: $resource_group, location: $location)"
echo "==> Deployment SKU under test: $sku_name"

if ! printf '%s' "$deployments_json" | jq -e 'type == "array"' >/dev/null 2>&1; then
  echo "ERROR: --deployments-json must be a valid JSON array of deployment objects." >&2
  exit 1
fi

models_json="$(az cognitiveservices account list-models \
  --resource-group "$resource_group" \
  --name "$account_name" \
  --subscription "$subscription" \
  -o json)"

status=0
index=0
while IFS=$'\t' read -r name model version capacity; do
  index=$((index + 1))

  if [[ -z "$name" || -z "$model" || -z "$version" || -z "$capacity" ]]; then
    echo "ERROR: Deployment entry $index is missing one of name/model/version/capacity." >&2
    status=1
    continue
  fi

  match="$(printf '%s' "$models_json" | jq -c --arg model "$model" --arg version "$version" '
    first(.[] | select(.name == $model and .version == $version and .format == "OpenAI"))
  ')"

  if [[ "$match" == "null" || -z "$match" ]]; then
    echo "[FAIL] $name -> model=$model version=$version not returned by az cognitiveservices account list-models"
    status=1
    continue
  fi

  priority_tier_skus="$(printf '%s' "$match" | jq -r '.capabilities.priorityTierSkus // ""')"
  chat_completion="$(printf '%s' "$match" | jq -r '.capabilities.chatCompletion // ""')"
  responses="$(printf '%s' "$match" | jq -r '.capabilities.responses // ""')"
  area="$(printf '%s' "$match" | jq -r '.capabilities.area // ""')"

  echo "[OK]   $name -> model=$model version=$version format=OpenAI capacity=$capacity"
  if [[ -n "$priority_tier_skus" ]]; then
    echo "       capabilities.priorityTierSkus=$priority_tier_skus"
  fi
  if [[ -n "$chat_completion" || -n "$responses" || -n "$area" ]]; then
    echo "       capabilities.chatCompletion=${chat_completion:-n/a} responses=${responses:-n/a} area=${area:-n/a}"
  fi

  if [[ "$probe_create" -eq 1 ]]; then
    temp_name="preflight-$(sanitize_name "$name")-$(LC_ALL=C od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
    echo "       probing create with deployment-name=$temp_name"
    create_output=""
    if create_output="$(probe_create_result "$resource_group" "$account_name" "$temp_name" "$model" "$version" "$sku_name" "$capacity" 2>&1)"; then
      echo "       create probe succeeded and temporary deployment was deleted"
    else
      echo "[FAIL] $name -> create probe failed"
      printf '%s\n' "$create_output" | sed 's/^/       /'
      status=1
    fi
  fi
done < <(printf '%s' "$deployments_json" | jq -r '.[] | [.name, .model, .version, (.capacity|tostring)] | @tsv')

exit "$status"