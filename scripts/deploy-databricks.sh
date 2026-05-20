#!/usr/bin/env bash
# scripts/deploy-databricks.sh
set -euo pipefail
set +x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${1:-${SCRIPT_DIR}/envs/databricks.env}"
SUBMODULE="${REPO_ROOT}/submodules/csb-brokerpak-databricks"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "ERROR: Environment file not found: ${ENV_FILE}"
  echo "       Copy scripts/envs/databricks.env.example → scripts/envs/databricks.env and fill in values."
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

unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
unset AWS_BUDGET_ALERT_EMAIL
unset GOOGLE_CREDENTIALS GOOGLE_PROJECT
unset GCP_BUDGET_ALERT_EMAIL
unset AZURE_BUDGET_CONTACT_EMAIL AZURE_BUDGET_WEBHOOK_URL
unset ARM_LOCATION ARM_TENANT_ID ARM_SUBSCRIPTION_ID ARM_CLIENT_ID ARM_CLIENT_SECRET
unset GSB_SERVICE_CSB_AWS_S3_BUCKET_PLANS GSB_SERVICE_CSB_AWS_POSTGRESQL_PLANS
unset GSB_SERVICE_CSB_AWS_MYSQL_PLANS GSB_SERVICE_CSB_AWS_REDIS_PLANS
unset GSB_SERVICE_CSB_AWS_SQS_PLANS GSB_SERVICE_CSB_AWS_BEDROCK_PLANS
unset GSB_SERVICE_CSB_AWS_AURORA_POSTGRESQL_PLANS GSB_SERVICE_CSB_AWS_AURORA_MYSQL_PLANS
unset GSB_SERVICE_CSB_AWS_MSSQL_PLANS GSB_SERVICE_CSB_AWS_DYNAMODB_NAMESPACE_PLANS
unset GSB_SERVICE_CSB_GOOGLE_POSTGRES_PLANS GSB_SERVICE_CSB_GOOGLE_MYSQL_PLANS
unset GSB_SERVICE_CSB_GOOGLE_STORAGE_BUCKET_PLANS GSB_SERVICE_CSB_GOOGLE_VERTEX_AI_PLANS
unset GSB_SERVICE_CSB_AZURE_MONGODB_PLANS GSB_SERVICE_CSB_AZURE_MSSQL_DB_PLANS
unset GSB_SERVICE_CSB_AZURE_MSSQL_DB_FAILOVER_GROUP_PLANS GSB_SERVICE_CSB_AZURE_MSSQL_FOG_RUN_FAILOVER_PLANS
unset GSB_SERVICE_CSB_AZURE_REDIS_PLANS GSB_SERVICE_CSB_AZURE_OPENAI_PLANS

set -a; source "${ENV_FILE}"; set +a

source "${SCRIPT_DIR}/lib/compact-json-env.sh"

[[ -z "${DATABRICKS_HOST:-}" ]] && { echo "ERROR: DATABRICKS_HOST is not set in ${ENV_FILE}"; exit 1; }
[[ -z "${DATABRICKS_TOKEN:-}" ]] && { echo "ERROR: DATABRICKS_TOKEN is not set in ${ENV_FILE}"; exit 1; }
[[ -z "${SECURITY_USER_PASSWORD:-}" ]] && { echo "ERROR: SECURITY_USER_PASSWORD is not set in ${ENV_FILE}"; exit 1; }

echo "==> [1/4] Building Databricks brokerpak..."
(cd "${SUBMODULE}" && make build)

echo "==> [2/4] Checking broker state database (${MYSQL_INSTANCE:-csb-sql})..."
export MSYQL_INSTANCE="${MYSQL_INSTANCE:-csb-sql}"
if ! cf service "${MSYQL_INSTANCE}" > /dev/null 2>&1; then
  echo "     Not found — creating via create-broker-db.sh..."
  "${SCRIPT_DIR}/create-broker-db.sh" "${MSYQL_INSTANCE}"
fi

echo "==> [3/4] Pushing CSB Databricks broker to CF as '${APP_NAME:-csb-databricks}'..."
(
  export APP_NAME="${APP_NAME:-csb-databricks}"
  export BROKER_NAME="${BROKER_NAME:-csb-databricks-sandbox}"
  export MANIFEST="${REPO_ROOT}/scripts/manifests/databricks-manifest.yml"
  export MSYQL_INSTANCE="${MYSQL_INSTANCE:-csb-sql}"
  cd "${SUBMODULE}"
  source "${SCRIPT_DIR}/lib/cf-push-broker.sh"
)

echo "==> [4/4] Deployment complete."
cf apps | grep "${APP_NAME:-csb-databricks}" || true
echo ""
echo "✓ Databricks broker '${BROKER_NAME:-csb-databricks-sandbox}' is registered in this CF space."
echo "  Provision example:"
echo "    cf create-service csb-databricks-model-serving sandbox-8h my-serving \\\""
echo "      -c '{\"entity_name\":\"system.ai.llama_v3_2_3b_instruct\",\"entity_version\":\"2\"}'"