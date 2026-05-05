#!/usr/bin/env bash
# scripts/deploy-azure.sh
#
# Builds and deploys the CSB Azure brokerpak to the current CF space.
#
# Prerequisites:
#   1. cf login -a api.fr.cloud.gov --sso  (targeted to gsa-tts-iae-lava-beds / dev)
#   2. Copy scripts/envs/azure.env.example → scripts/envs/azure.env and fill values
#   3. Run: pnpm run broker:db   (creates csb-sql MySQL instance if not present)
#
# Usage:
#   ./scripts/deploy-azure.sh [path/to/azure.env]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
set +x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/envs/azure.env}"
SUBMODULE="${REPO_ROOT}/submodules/csb-brokerpak-azure"

# ── Validation ────────────────────────────────────────────────────────────────
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Environment file not found: ${ENV_FILE}"
  echo "       Copy scripts/envs/azure.env.example → scripts/envs/azure.env and fill in values."
  exit 1
fi

if [[ ! -d "${SUBMODULE}" ]]; then
  echo "ERROR: Submodule not initialised. Run: pnpm run submodule:init"
  exit 1
fi

cf target > /dev/null 2>&1 || {
  echo "ERROR: Not logged in to CF. Run: cf login -a api.fr.cloud.gov --sso"
  exit 1
}

# ── Load env ──────────────────────────────────────────────────────────────────
# Clear unrelated provider vars that may be left exported in a persistent shell.
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
unset AWS_BUDGET_ALERT_EMAIL
unset GOOGLE_CREDENTIALS GOOGLE_PROJECT
unset GCP_BUDGET_ALERT_EMAIL
unset GSB_SERVICE_CSB_AWS_S3_BUCKET_PLANS GSB_SERVICE_CSB_AWS_POSTGRESQL_PLANS
unset GSB_SERVICE_CSB_AWS_MYSQL_PLANS GSB_SERVICE_CSB_AWS_REDIS_PLANS
unset GSB_SERVICE_CSB_AWS_SQS_PLANS GSB_SERVICE_CSB_AWS_BEDROCK_PLANS
unset GSB_SERVICE_CSB_AWS_AURORA_POSTGRESQL_PLANS GSB_SERVICE_CSB_AWS_AURORA_MYSQL_PLANS
unset GSB_SERVICE_CSB_AWS_MSSQL_PLANS GSB_SERVICE_CSB_AWS_DYNAMODB_NAMESPACE_PLANS
unset GSB_SERVICE_CSB_GOOGLE_POSTGRES_PLANS GSB_SERVICE_CSB_GOOGLE_MYSQL_PLANS
unset GSB_SERVICE_CSB_GOOGLE_STORAGE_BUCKET_PLANS GSB_SERVICE_CSB_GOOGLE_VERTEX_AI_PLANS

# shellcheck source=/dev/null
set -a; source "${ENV_FILE}"; set +a

# Compact multiline JSON plan values to single lines (required by make build)
# shellcheck source=lib/compact-json-env.sh
source "${SCRIPT_DIR}/lib/compact-json-env.sh"

if [[ -n "${GSB_PROVISION_DEFAULTS:-}" ]]; then
  sanitized_defaults=$(printf '%s' "${GSB_PROVISION_DEFAULTS}" | jq -c 'del(.resource_group)')
  if [[ "${sanitized_defaults}" != "${GSB_PROVISION_DEFAULTS}" ]]; then
    echo "INFO: Removing global resource_group from GSB_PROVISION_DEFAULTS for Azure deploys; instance-level defaults and overrides should control Azure resource groups."
    export GSB_PROVISION_DEFAULTS="${sanitized_defaults}"
  fi
fi

require_real_value() {
  local var_name="$1"
  local value="${!var_name:-}"

  if [[ -z "${value}" ]]; then
    echo "ERROR: ${var_name} is not set in ${ENV_FILE}"
    exit 1
  fi

  case "${value}" in
    *CHANGEME*|xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx|your-*|"<"*">")
      echo "ERROR: ${var_name} in ${ENV_FILE} is still a placeholder value"
      exit 1
      ;;
  esac
}

# Validate required Azure-specific vars before proceeding
require_real_value SECURITY_USER_PASSWORD
require_real_value ARM_TENANT_ID
require_real_value ARM_SUBSCRIPTION_ID
require_real_value ARM_CLIENT_ID
require_real_value ARM_CLIENT_SECRET

run_azure_openai_preflight() {
  if [[ "${AZURE_OPENAI_PREFLIGHT:-0}" != "1" ]]; then
    return 0
  fi

  if [[ -z "${AZURE_OPENAI_PREFLIGHT_DEPLOYMENTS_JSON:-}" ]]; then
    echo "ERROR: AZURE_OPENAI_PREFLIGHT=1 requires AZURE_OPENAI_PREFLIGHT_DEPLOYMENTS_JSON in ${ENV_FILE}" >&2
    exit 1
  fi

  local preflight_location="${AZURE_OPENAI_PREFLIGHT_LOCATION:-${ARM_LOCATION:-}}"
  if [[ -z "${preflight_location}" && -n "${GSB_PROVISION_DEFAULTS:-}" ]]; then
    preflight_location="$(printf '%s' "${GSB_PROVISION_DEFAULTS}" | jq -r '.location // empty')"
  fi
  preflight_location="${preflight_location:-eastus}"

  local preflight_args=(
    --location "${preflight_location}"
    --subscription "${ARM_SUBSCRIPTION_ID}"
    --deployments-json "${AZURE_OPENAI_PREFLIGHT_DEPLOYMENTS_JSON}"
    --sku-name "${AZURE_OPENAI_PREFLIGHT_SKU_NAME:-Standard}"
  )

  if [[ -n "${AZURE_OPENAI_PREFLIGHT_RESOURCE_GROUP:-}" ]]; then
    preflight_args+=(--resource-group "${AZURE_OPENAI_PREFLIGHT_RESOURCE_GROUP}")
  fi

  if [[ -n "${AZURE_OPENAI_PREFLIGHT_ACCOUNT_NAME:-}" ]]; then
    preflight_args+=(--account-name "${AZURE_OPENAI_PREFLIGHT_ACCOUNT_NAME}")
  fi

  if [[ "${AZURE_OPENAI_PREFLIGHT_PROBE_CREATE:-0}" == "1" ]]; then
    preflight_args+=(--probe-create)
  fi

  if ! command -v az >/dev/null 2>&1; then
    echo "ERROR: AZURE_OPENAI_PREFLIGHT=1 requires the az CLI to be installed and authenticated." >&2
    exit 1
  fi

  echo "==> [preflight] Validating Azure OpenAI deployment matrix with Azure CLI..."
  az account set --subscription "${ARM_SUBSCRIPTION_ID}" >/dev/null
  "${SCRIPT_DIR}/azure-openai-preflight.sh" "${preflight_args[@]}"
}

run_azure_openai_preflight

# ── Patch upstream provider_display_name (VMware → GSA TTS) ─────────────────
# shellcheck source=lib/patch-provider-display-name.sh
source "${SCRIPT_DIR}/lib/patch-provider-display-name.sh"

# ── Step 1: Build brokerpak ──────────────────────────────────────────────────
echo "==> [1/4] Building Azure brokerpak..."
(cd "${SUBMODULE}" && make build)

# ── Step 2: Ensure backing DB exists ─────────────────────────────────────────
echo "==> [2/4] Checking broker state database (${MYSQL_INSTANCE:-csb-sql})..."
export MSYQL_INSTANCE="${MYSQL_INSTANCE:-csb-sql}"
if ! cf service "${MSYQL_INSTANCE}" > /dev/null 2>&1; then
  echo "     Not found — creating via create-broker-db.sh..."
  "${SCRIPT_DIR}/create-broker-db.sh" "${MSYQL_INSTANCE}"
fi

# ── Step 3: Push broker + register ──────────────────────────────────────────
echo "==> [3/4] Pushing CSB Azure broker to CF as '${APP_NAME:-csb-azure}'..."
(
  export APP_NAME="${APP_NAME:-csb-azure}"
  export BROKER_NAME="${BROKER_NAME:-csb-azure-sandbox}"
  export MANIFEST="${REPO_ROOT}/scripts/manifests/azure-manifest.yml"
  export MSYQL_INSTANCE="${MYSQL_INSTANCE:-csb-sql}"
  cd "${SUBMODULE}"
  source "${SCRIPT_DIR}/lib/cf-push-broker.sh"
)

# ── Step 4: Confirm ──────────────────────────────────────────────────────────
echo "==> [4/4] Deployment complete."
cf apps | grep "${APP_NAME:-csb-azure}" || true
echo ""
echo "✓ Azure broker '${BROKER_NAME:-csb-azure-sandbox}' is registered in this CF space."
echo "  Provision example:"
echo "    cf create-service csb-azure-postgresql sandbox-8h my-pg \\"
echo "      -c '{\"project\":\"sprint-42\",\"owner\":\"owner@example.gov\"}'"
