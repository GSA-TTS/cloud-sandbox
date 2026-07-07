#!/usr/bin/env bash
# scripts/deploy-aws.sh
#
# Builds and deploys the CSB AWS brokerpak to the current CF space.
#
# Prerequisites:
#   1. cf login -a api.fr.cloud.gov --sso  (targeted to gsa-tts-iae-lava-beds / dev)
#   2. Copy scripts/envs/aws.env.example → scripts/envs/aws.env and fill values
#   3. Run: pnpm run broker:db   (creates csb-sql MySQL instance if not present)
#   4. Ensure Go and make are installed (or use Docker — see submodule README)
#
# Usage:
#   ./scripts/deploy-aws.sh [path/to/aws.env]
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
set +x  # Do not echo secrets

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/envs/aws.env}"
SUBMODULE="${REPO_ROOT}/submodules/csb-brokerpak-aws"

# ── Validation ────────────────────────────────────────────────────────────────
if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Environment file not found: ${ENV_FILE}"
  echo "       Copy scripts/envs/aws.env.example → scripts/envs/aws.env and fill in values."
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

# ── Load env (secrets stay in memory only) ───────────────────────────────────
# Clear unrelated provider vars that may be left exported in a persistent shell.
unset GOOGLE_CREDENTIALS GOOGLE_PROJECT
unset GCP_BUDGET_ALERT_EMAIL
unset AZURE_BUDGET_CONTACT_EMAIL AZURE_BUDGET_WEBHOOK_URL
unset ARM_LOCATION ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET
unset GSB_SERVICE_CSB_GOOGLE_POSTGRES_PLANS GSB_SERVICE_CSB_GOOGLE_MYSQL_PLANS
unset GSB_SERVICE_CSB_GOOGLE_STORAGE_BUCKET_PLANS GSB_SERVICE_CSB_GOOGLE_VERTEX_AI_PLANS
unset GSB_SERVICE_CSB_AZURE_MONGODB_PLANS GSB_SERVICE_CSB_AZURE_MSSQL_DB_PLANS
unset GSB_SERVICE_CSB_AZURE_MSSQL_DB_FAILOVER_GROUP_PLANS GSB_SERVICE_CSB_AZURE_MSSQL_FOG_RUN_FAILOVER_PLANS
unset GSB_SERVICE_CSB_AZURE_REDIS_PLANS GSB_SERVICE_CSB_AZURE_OPENAI_PLANS

# shellcheck source=/dev/null
set -a; source "${ENV_FILE}"; set +a

# Compact multiline JSON plan values to single lines (required by make build)
# shellcheck source=lib/compact-json-env.sh
source "${SCRIPT_DIR}/lib/compact-json-env.sh"

# ── Patch upstream provider_display_name (VMware → GSA TTS) ─────────────────
# shellcheck source=lib/patch-provider-display-name.sh
source "${SCRIPT_DIR}/lib/patch-provider-display-name.sh"

# ── Step 1: Build brokerpak ──────────────────────────────────────────────────
echo "==> [1/4] Building AWS brokerpak..."
(cd "${SUBMODULE}" && make build)

# ── Step 2: Ensure backing DB exists ─────────────────────────────────────────
echo "==> [2/4] Checking broker state database (${MYSQL_INSTANCE:-csb-sql})..."
export MSYQL_INSTANCE="${MYSQL_INSTANCE:-csb-sql}"
if ! cf service "${MSYQL_INSTANCE}" > /dev/null 2>&1; then
  echo "     Not found — creating via create-broker-db.sh..."
  "${SCRIPT_DIR}/create-broker-db.sh" "${MSYQL_INSTANCE}"
fi

# ── Step 3: Push broker + register ──────────────────────────────────────────
echo "==> [3/4] Pushing CSB AWS broker to CF as '${APP_NAME:-csb-aws}'..."
(
  export APP_NAME="${APP_NAME:-csb-aws}"
  export BROKER_NAME="${BROKER_NAME:-csb-aws-sandbox}"
  # Use our manifest override (1G memory — submodule default is 4G, exceeds cloud.gov quota)
  export MANIFEST="${REPO_ROOT}/scripts/manifests/aws-manifest.yml"
  export MSYQL_INSTANCE="${MYSQL_INSTANCE:-csb-sql}"
  # Run from inside the submodule so the brokerpak ZIP is on the path
  cd "${SUBMODULE}"
  source "${SCRIPT_DIR}/lib/cf-push-broker.sh"
)

# ── Step 4: Confirm ──────────────────────────────────────────────────────────
echo "==> [4/4] Deployment complete."
cf apps | grep "${APP_NAME:-csb-aws}" || true
echo ""
echo "✓ AWS broker '${BROKER_NAME:-csb-aws-sandbox}' is registered in this CF space."
echo "  Run 'cf marketplace' to see available services."
echo "  Provision example:"
echo "    cf create-service csb-aws-postgresql sandbox-8h my-db \\"
echo "      -c '{\"project\":\"sprint-42\",\"owner\":\"owner@example.gov\"}'"
