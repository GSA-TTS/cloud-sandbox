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
# shellcheck source=/dev/null
set -a; source "${ENV_FILE}"; set +a

# Compact multiline JSON plan values to single lines (required by make build)
# shellcheck source=lib/compact-json-env.sh
source "${SCRIPT_DIR}/lib/compact-json-env.sh"

# Validate required Azure-specific vars before proceeding
[[ -z "${ARM_TENANT_ID:-}" ]]       && { echo "ERROR: ARM_TENANT_ID is not set in ${ENV_FILE}"; exit 1; }
[[ -z "${ARM_SUBSCRIPTION_ID:-}" ]] && { echo "ERROR: ARM_SUBSCRIPTION_ID is not set in ${ENV_FILE}"; exit 1; }
[[ -z "${ARM_CLIENT_ID:-}" ]]       && { echo "ERROR: ARM_CLIENT_ID is not set in ${ENV_FILE}"; exit 1; }
[[ -z "${ARM_CLIENT_SECRET:-}" ]]   && { echo "ERROR: ARM_CLIENT_SECRET is not set in ${ENV_FILE}"; exit 1; }

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
  export MANIFEST="${SUBMODULE}/cf-manifest.yml"
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
echo "      -c '{\"project\":\"sprint-42\",\"owner\":\"you@gsa.gov\"}'"
