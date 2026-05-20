#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  scripts/refresh-model-catalogs.sh [options]

Refreshes local JSON model catalogs for the cloud providers used by the brokerpaks.
Catalog files are written to .cache/model-catalogs by default.

Options:
  --provider <aws|azure|gcp|all>    Which provider catalog(s) to refresh. Default: all
  --cache-dir <path>                Output directory for JSON cache files.
  --aws-env <path>                  AWS env file. Default: scripts/envs/aws.env
  --aws-region <region>             Bedrock region. Default: us-east-1
  --azure-env <path>                Azure env file. Default: scripts/envs/azure.env
  --azure-location <location>       Azure OpenAI location. Default: eastus2
  --azure-subscription <id>         Azure subscription override.
  --azure-resource-group <name>     Azure OpenAI probe resource group override.
  --azure-account-name <name>       Azure OpenAI probe account override.
  --gcp-env <path>                  GCP env file. Default: scripts/envs/gcp.env
  --gcp-project <id>                GCP project override.
  --help                            Show this message.

Examples:
  pnpm run catalog:refresh
  pnpm run catalog:refresh:aws -- --aws-region us-west-2
  pnpm run catalog:refresh:azure -- --azure-location eastus
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# shellcheck source=lib/model-catalog-common.sh
source "${SCRIPT_DIR}/lib/model-catalog-common.sh"

provider="all"
cache_dir="${REPO_ROOT}/.cache/model-catalogs"
aws_env="${SCRIPT_DIR}/envs/aws.env"
aws_region="us-east-1"
azure_env="${SCRIPT_DIR}/envs/azure.env"
azure_location="eastus2"
azure_subscription=""
azure_resource_group=""
azure_account_name=""
gcp_env="${SCRIPT_DIR}/envs/gcp.env"
gcp_project_override=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --provider)
      provider="$2"
      shift 2
      ;;
    --cache-dir)
      cache_dir="$2"
      shift 2
      ;;
    --aws-env)
      aws_env="$2"
      shift 2
      ;;
    --aws-region)
      aws_region="$2"
      shift 2
      ;;
    --azure-env)
      azure_env="$2"
      shift 2
      ;;
    --azure-location)
      azure_location="$2"
      shift 2
      ;;
    --azure-subscription)
      azure_subscription="$2"
      shift 2
      ;;
    --azure-resource-group)
      azure_resource_group="$2"
      shift 2
      ;;
    --azure-account-name)
      azure_account_name="$2"
      shift 2
      ;;
    --gcp-env)
      gcp_env="$2"
      shift 2
      ;;
    --gcp-project)
      gcp_project_override="$2"
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
  aws|azure|gcp|all)
    ;;
  *)
    echo "ERROR: --provider must be one of aws, azure, gcp, all." >&2
    exit 1
    ;;
esac

require_cmd jq
mkdir -p "$cache_dir"

refresh_aws_catalog() {
  require_cmd aws

  local auth_source="active-environment"
  local raw output_path refreshed_at
  refreshed_at="$(timestamp_utc)"

  if [[ -z "${AWS_ACCESS_KEY_ID:-}" && -z "${AWS_PROFILE:-}" && -f "$aws_env" ]]; then
    load_env_file "$aws_env"
    auth_source="$aws_env"
  fi

  if ! aws sts get-caller-identity --no-cli-pager >/dev/null 2>&1; then
    cat >&2 <<EOF
ERROR: AWS authentication is not valid for catalog refresh.
Refresh the active AWS session or export a working AWS profile before retrying.
The script also accepts credentials from $aws_env when that file contains valid keys.
EOF
    exit 1
  fi

  echo "==> Refreshing AWS Bedrock model catalog for region $aws_region"
  raw="$(aws bedrock list-foundation-models --region "$aws_region" --no-cli-pager)"
  output_path="${cache_dir}/aws-bedrock-${aws_region}.json"

  printf '%s' "$raw" | jq \
    --arg generated_at "$refreshed_at" \
    --arg region "$aws_region" \
    --arg auth_source "$auth_source" \
    --arg output_path "$output_path" '
    {
      schema_version: "v1",
      generated_at: $generated_at,
      provider: "aws",
      service: "bedrock",
      scope: {
        region: $region
      },
      source: {
        type: "aws-cli",
        auth_source: $auth_source,
        command: ("aws bedrock list-foundation-models --region " + $region)
      },
      metadata_notes: [
        "AWS CLI model summaries do not expose context-window or token-pricing fields.",
        "Use provisioner_contract.models as the refreshable broker input candidate list."
      ],
      provisioner_contract: {
        field_name: "models",
        value_type: "json-string-array",
        models: [(.modelSummaries[]?.modelId)]
      },
      models: [
        .modelSummaries[]? | {
          id: .modelId,
          name: .modelName,
          provider_name: .providerName,
          input_modalities: (.inputModalities // []),
          output_modalities: (.outputModalities // []),
          customizations_supported: (.customizationsSupported // []),
          inference_types_supported: (.inferenceTypesSupported // []),
          response_streaming_supported: (.responseStreamingSupported // false),
          lifecycle_status: (.modelLifecycle.status // null),
          context_window_tokens: null,
          max_output_tokens: null,
          pricing: null,
          raw: .
        }
      ]
    }
  ' > "$output_path"

  echo "    wrote $output_path"
}

refresh_azure_catalog() {
  require_cmd az

  local auth_source="active-az-session"
  local subscription account_lookup account_rg account_name raw account_json deployments_raw output_path refreshed_at
  refreshed_at="$(timestamp_utc)"

  if [[ -f "$azure_env" ]]; then
    load_env_file "$azure_env"
  fi

  if [[ -n "${ARM_CLIENT_ID:-}" && -n "${ARM_CLIENT_SECRET:-}" && -n "${ARM_TENANT_ID:-}" ]]; then
    az login \
      --service-principal \
      --username "$ARM_CLIENT_ID" \
      --password "$ARM_CLIENT_SECRET" \
      --tenant "$ARM_TENANT_ID" \
      --output none >/dev/null
    auth_source="$azure_env"
  fi

  subscription="$azure_subscription"
  if [[ -z "$subscription" ]]; then
    subscription="${ARM_SUBSCRIPTION_ID:-}"
  fi
  if [[ -z "$subscription" ]]; then
    subscription="$(az account show --query id -o tsv)"
  fi

  if [[ -z "$subscription" ]]; then
    echo "ERROR: Could not determine an Azure subscription for model catalog refresh." >&2
    exit 1
  fi

  az account set --subscription "$subscription" >/dev/null

  account_rg="$azure_resource_group"
  account_name="$azure_account_name"
  if [[ -z "$account_rg" || -z "$account_name" ]]; then
    account_lookup="$(az cognitiveservices account list --subscription "$subscription" -o json | jq -r --arg location "$azure_location" '
      map(select(.kind == "OpenAI" and .location == $location and .properties.provisioningState == "Succeeded"))
      | first
      | if . == null then empty else [.resourceGroup, .name] | @tsv end
    ')"

    if [[ -z "$account_lookup" ]]; then
      echo "ERROR: No succeeded Azure OpenAI account found in $subscription for location $azure_location." >&2
      echo "       Pass --azure-resource-group and --azure-account-name to use an explicit probe account." >&2
      exit 1
    fi

    if [[ -z "$account_rg" ]]; then
      account_rg="${account_lookup%%$'\t'*}"
    fi
    if [[ -z "$account_name" ]]; then
      account_name="${account_lookup#*$'\t'}"
    fi
  fi

  echo "==> Refreshing Azure OpenAI model catalog for location $azure_location"
  account_json="$(az cognitiveservices account show \
    --resource-group "$account_rg" \
    --name "$account_name" \
    --subscription "$subscription" \
    -o json)"
  deployments_raw="$(az cognitiveservices account deployment list \
    --resource-group "$account_rg" \
    --name "$account_name" \
    --subscription "$subscription" \
    -o json)"
  raw="$(az cognitiveservices account list-models \
    --resource-group "$account_rg" \
    --name "$account_name" \
    --subscription "$subscription" \
    -o json)"
  output_path="${cache_dir}/azure-openai-${azure_location}.json"

  printf '%s' "$raw" | jq \
    --arg generated_at "$refreshed_at" \
    --arg location "$azure_location" \
    --arg subscription "$subscription" \
    --arg resource_group "$account_rg" \
    --arg account_name "$account_name" \
    --arg auth_source "$auth_source" \
    --argjson account "$account_json" \
    --argjson deployments "$deployments_raw" '
    {
      schema_version: "v1",
      generated_at: $generated_at,
      provider: "azure",
      service: "openai",
      scope: {
        location: $location,
        subscription: $subscription,
        probe_resource_group: $resource_group,
        probe_account_name: $account_name
      },
      source: {
        type: "azure-cli",
        auth_source: $auth_source,
        command: ("az cognitiveservices account list-models --resource-group " + $resource_group + " --name " + $account_name + " --subscription " + $subscription)
      },
      connection: {
        subscription: $subscription,
        resource_group: $resource_group,
        account_name: $account_name,
        endpoint: ($account.properties.endpoint // null),
        custom_subdomain_name: ($account.properties.customSubDomainName // null),
        location: ($account.location // $location),
        kind: ($account.kind // null),
        sku: ($account.sku.name // null)
      },
      metadata_notes: [
        "Azure CLI exposes deployment SKUs and capacity hints, but most entries do not include explicit per-token pricing.",
        "provisioner_contract.deployments_json_candidates is a generated starting point, not an operator-approved default set.",
        "models is the account catalog; deployments and effective_connection_models are the authoritative connection surface for bound clients."
      ],
      provisioner_contract: {
        field_name: "deployments_json",
        value_type: "json-string-array-of-objects",
        deployments_json_candidates: [
          .[]
          | select(.format == "OpenAI" and ((.capabilities.inference // "false") == "true"))
          | {
              name: (.name | ascii_downcase | gsub("[^a-z0-9]+"; "-") | gsub("(^-|-$)"; "")),
              model: .name,
              version: .version,
              capacity: (.skus[0].capacity.default // .maxCapacity // 10),
              sku_name: (.skus[0].name // null)
            }
        ]
      },
      deployments: [
        $deployments[]? as $deployment
        | ($deployment.properties.model.name // null) as $model_name
        | ($deployment.properties.model.version // null) as $model_version
        | (first(.[] | select(.name == $model_name and .version == $model_version and .format == "OpenAI")) // {}) as $catalog_model
        | {
            name: ($deployment.name // null),
            model: $model_name,
            version: $model_version,
            format: ($deployment.properties.model.format // null),
            sku_name: ($deployment.sku.name // null),
            sku_capacity: ($deployment.sku.capacity // null),
            provisioning_state: ($deployment.properties.provisioningState // null),
            chat_completion: (($catalog_model.capabilities.chatCompletion // "false") == "true"),
            responses: (($catalog_model.capabilities.responses // "false") == "true"),
            completions: (($catalog_model.capabilities.completions // "false") == "true"),
            lifecycle_status: ($catalog_model.lifecycleStatus // null),
            raw: $deployment
          }
      ],
      effective_connection_models: [
        $deployments[]? as $deployment
        | ($deployment.properties.model.name // null) as $model_name
        | ($deployment.properties.model.version // null) as $model_version
        | (first(.[] | select(.name == $model_name and .version == $model_version and .format == "OpenAI")) // {}) as $catalog_model
        | select(
            (($catalog_model.capabilities.chatCompletion // "false") == "true")
            or (($catalog_model.capabilities.responses // "false") == "true")
            or (($catalog_model.capabilities.completions // "false") == "true")
          )
        | {
            deployment_name: ($deployment.name // null),
            model: $model_name,
            version: $model_version,
            endpoint: ($account.properties.endpoint // null),
            api_style: if (($catalog_model.capabilities.responses // "false") == "true") then "responses" else "chat-completions" end,
            lifecycle_status: ($catalog_model.lifecycleStatus // null)
          }
      ],
      models: [
        .[] | {
          id: (.name + "@" + .version),
          name: .name,
          version: .version,
          format: .format,
          lifecycle_status: (.lifecycleStatus // null),
          is_default_version: (.isDefaultVersion // false),
          deprecation: (.deprecation // null),
          capabilities: (.capabilities // {}),
          max_capacity: (.maxCapacity // null),
          context_window_tokens: (.capabilities.maxContextTokens // .capabilities.contextWindow // null),
          max_output_tokens: (.capabilities.maxOutputTokens // null),
          pricing: {
            skus: ((.skus // []) | map({
              name: .name,
              usage_name: (.usageName // null),
              cost: (.cost // null)
            }))
          },
          raw: .
        }
      ]
    }
  ' > "$output_path"

  echo "    wrote $output_path"
}

refresh_gcp_catalogs() {
  require_cmd gcloud
  require_cmd node

  local gcp_project="${gcp_project_override}"
  local auth_source="active-gcloud-session"
  local refreshed_at tmp_key gcloud_config all_models output_vertex output_gemini cleanup_needed=0 exit_code=0
  refreshed_at="$(timestamp_utc)"

  if [[ -f "$gcp_env" ]]; then
    load_env_file "$gcp_env"
  fi

  if [[ -z "$gcp_project" ]]; then
    gcp_project="${GOOGLE_PROJECT:-}"
  fi
  if [[ -z "$gcp_project" ]]; then
    gcp_project="$(gcloud config get-value project 2>/dev/null || true)"
  fi

  if [[ -z "$gcp_project" ]]; then
    echo "ERROR: Could not determine a GCP project for model catalog refresh." >&2
    exit 1
  fi

  tmp_key="$(mktemp /tmp/cloud-sandbox-gcp-key.XXXXXX.json)"
  gcloud_config="cloud-sandbox-model-catalog-$$"

  cleanup_gcp() {
    if [[ "$cleanup_needed" -eq 1 ]]; then
      gcloud config configurations activate default --quiet >/dev/null 2>&1 || true
      gcloud config configurations delete "$gcloud_config" --quiet >/dev/null 2>&1 || true
      rm -f "$tmp_key"
    fi
  }

  trap cleanup_gcp RETURN

  if [[ -n "${GOOGLE_CREDENTIALS:-}" ]]; then
    normalize_gcp_credentials_to_file "$tmp_key"
    gcloud config configurations create "$gcloud_config" --quiet >/dev/null 2>&1 || true
    gcloud config configurations activate "$gcloud_config" --quiet >/dev/null
    gcloud auth activate-service-account --key-file="$tmp_key" --quiet >/dev/null
    gcloud config set project "$gcp_project" --quiet >/dev/null
    auth_source="$gcp_env"
    cleanup_needed=1
  else
    if ! gcloud auth application-default print-access-token >/dev/null 2>&1; then
      ensure_gcloud_adc_guidance "$gcp_project"
    fi
    gcloud config set project "$gcp_project" --quiet >/dev/null
  fi

  echo "==> Refreshing GCP Model Garden catalogs for project $gcp_project"
  all_models="$(gcloud ai model-garden models list --limit=unlimited --format=json)"
  output_vertex="${cache_dir}/gcp-vertex-model-garden-${gcp_project}.json"
  output_gemini="${cache_dir}/gcp-gemini-api-${gcp_project}.json"

  printf '%s' "$all_models" | jq \
    --arg generated_at "$refreshed_at" \
    --arg project "$gcp_project" \
    --arg auth_source "$auth_source" '
    {
      schema_version: "v1",
      generated_at: $generated_at,
      provider: "gcp",
      service: "vertex-ai",
      scope: {
        project: $project,
        endpoint: "us-central1-aiplatform.googleapis.com"
      },
      source: {
        type: "gcloud",
        auth_source: $auth_source,
        command: "gcloud ai model-garden models list --limit=unlimited --format=json"
      },
      metadata_notes: [
        "Model Garden list results do not expose token pricing or context-window limits in the installed gcloud CLI.",
        "provisioner_contract.models is a refreshable superset; curate it before pinning broker defaults."
      ],
      provisioner_contract: {
        field_name: "models",
        value_type: "json-string-array",
        models: [.[].name | split("/") | last]
      },
      models: [
        .[] | {
          id: (.name | split("/") | last),
          full_name: .name,
          publisher: (.name | split("/") | .[1]),
          version_id: (.versionId // null),
          launch_stage: (.launchStage // null),
          supported_actions: ((.supportedActions // {}) | keys),
          context_window_tokens: null,
          max_output_tokens: null,
          pricing: null,
          raw: .
        }
      ]
    }
  ' > "$output_vertex"

  printf '%s' "$all_models" | jq \
    --arg generated_at "$refreshed_at" \
    --arg project "$gcp_project" \
    --arg auth_source "$auth_source" '
    {
      schema_version: "v1",
      generated_at: $generated_at,
      provider: "gcp",
      service: "gemini-api",
      scope: {
        project: $project
      },
      source: {
        type: "gcloud",
        auth_source: $auth_source,
        command: "gcloud ai model-garden models list --limit=unlimited --format=json"
      },
      metadata_notes: [
        "This Gemini cache is derived from Model Garden IDs because the installed gcloud CLI does not expose a separate Gemini API model-list command.",
        "Use an empty broker models array to mean all Gemini API models, or lift explicit IDs from provisioner_contract.models for review workflows."
      ],
      provisioner_contract: {
        field_name: "models",
        value_type: "json-string-array",
        models: [
          .[]
          | (.name | split("/") | last)
          | select(test("^gemini"; "i"))
        ]
      },
      models: [
        .[]
        | select((.name | split("/") | last) | test("^gemini"; "i"))
        | {
            id: (.name | split("/") | last),
            full_name: .name,
            version_id: (.versionId // null),
            launch_stage: (.launchStage // null),
            context_window_tokens: null,
            max_output_tokens: null,
            pricing: null,
            raw: .
          }
      ]
    }
  ' > "$output_gemini"

  echo "    wrote $output_vertex"
  echo "    wrote $output_gemini"
}

case "$provider" in
  aws)
    refresh_aws_catalog
    ;;
  azure)
    refresh_azure_catalog
    ;;
  gcp)
    refresh_gcp_catalogs
    ;;
  all)
    refresh_aws_catalog
    refresh_azure_catalog
    refresh_gcp_catalogs
    ;;
esac