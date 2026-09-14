#!/usr/bin/env bash
# scripts/lib/cf-push-broker.sh
#
# Full CF push + service-bind + DB env injection + start + broker registration.
# Replaces the submodule's push-broker.sh to properly handle cloud.gov's
# aws-rds VCAP_SERVICES format, which the CSB cannot auto-detect.
#
# Required env vars (caller must export before sourcing):
#   APP_NAME, BROKER_NAME, MANIFEST, MSYQL_INSTANCE (sic — typo in original)
#   SECURITY_USER_NAME, SECURITY_USER_PASSWORD
#   All GSB_SERVICE_* plan vars (already compacted to single-line JSON)
#
# Called by: scripts/deploy-aws.sh  deploy-gcp.sh  deploy-azure.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
set +x  # Never echo secrets

MYSQL_INST="${MSYQL_INSTANCE:-csb-sql}"

# ── Build a temp CF manifest without secrets; env is set after push ──────────
cfmf="/tmp/cf-manifest-$$.yml"
touch "$cfmf"
trap "rm -f $cfmf" EXIT
chmod 600 "$cfmf"
cat "${MANIFEST}" > "$cfmf"

ensure_cf_target() {
  if [[ -n "${DEPLOY_CF_ORG:-}" && -n "${DEPLOY_CF_SPACE:-}" ]]; then
    cf target -o "${DEPLOY_CF_ORG}" -s "${DEPLOY_CF_SPACE}" >/dev/null
  fi
}

set_app_env() { ensure_cf_target; cf set-env "${APP_NAME}" "$1" "$2" >/dev/null; }

managed_optional_env_vars=(
  DATABRICKS_HOST
  DATABRICKS_TOKEN
  AWS_ACCESS_KEY_ID
  AWS_SECRET_ACCESS_KEY
  GOOGLE_CREDENTIALS
  GOOGLE_PROJECT
  ARM_LOCATION
  ARM_TENANT_ID
  ARM_SUBSCRIPTION_ID
  ARM_CLIENT_ID
  ARM_CLIENT_SECRET
  GSB_PROVISION_DEFAULTS
  GSB_SERVICE_CSB_AWS_S3_BUCKET_PLANS
  GSB_SERVICE_CSB_AWS_POSTGRESQL_PLANS
  GSB_SERVICE_CSB_AWS_MYSQL_PLANS
  GSB_SERVICE_CSB_AWS_REDIS_PLANS
  GSB_SERVICE_CSB_AWS_SQS_PLANS
  GSB_SERVICE_CSB_AWS_BEDROCK_PLANS
  GSB_SERVICE_CSB_AWS_AURORA_POSTGRESQL_PLANS
  GSB_SERVICE_CSB_AWS_AURORA_MYSQL_PLANS
  GSB_SERVICE_CSB_AWS_MSSQL_PLANS
  GSB_SERVICE_CSB_AWS_DYNAMODB_NAMESPACE_PLANS
  GSB_SERVICE_CSB_GOOGLE_POSTGRES_PLANS
  GSB_SERVICE_CSB_GOOGLE_MYSQL_PLANS
  GSB_SERVICE_CSB_GOOGLE_STORAGE_BUCKET_PLANS
  GSB_SERVICE_CSB_GOOGLE_VERTEX_AI_PLANS
  GSB_SERVICE_CSB_AZURE_MONGODB_PLANS
  GSB_SERVICE_CSB_AZURE_MSSQL_DB_PLANS
  GSB_SERVICE_CSB_AZURE_MSSQL_DB_FAILOVER_GROUP_PLANS
  GSB_SERVICE_CSB_AZURE_MSSQL_FOG_RUN_FAILOVER_PLANS
  GSB_SERVICE_CSB_AZURE_REDIS_PLANS
  GSB_SERVICE_CSB_AZURE_OPENAI_PLANS
  GSB_SERVICE_CSB_DATABRICKS_MODEL_SERVING_PLANS
)

# ── Step A: push without starting ────────────────────────────────────────────
echo "  → cf push --no-start (manifest: $cfmf)"
ensure_cf_target
cf push --no-start -f "${cfmf}" --var app="${APP_NAME}"

ensure_cf_target

# Set broker env after push so cf does not echo secrets in the manifest diff.
echo "  → setting broker environment on ${APP_NAME}..."
set_app_env "SECURITY_USER_NAME" "${SECURITY_USER_NAME}"
set_app_env "SECURITY_USER_PASSWORD" "${SECURITY_USER_PASSWORD}"
set_app_env "BROKERPAK_UPDATES_ENABLED" "${BROKERPAK_UPDATES_ENABLED:-true}"
set_app_env "TERRAFORM_UPGRADES_ENABLED" "${TERRAFORM_UPGRADES_ENABLED:-true}"
set_app_env "CSB_DISABLE_TF_UPGRADE_PROVIDER_RENAMES" "${CSB_DISABLE_TF_UPGRADE_PROVIDER_RENAMES:-false}"
set_app_env "GSB_COMPATIBILITY_ENABLE_BETA_SERVICES" "${GSB_COMPATIBILITY_ENABLE_BETA_SERVICES:-true}"
[[ -n "${AWS_ACCESS_KEY_ID:-}" ]] && set_app_env "AWS_ACCESS_KEY_ID" "${AWS_ACCESS_KEY_ID}"
[[ -n "${AWS_SECRET_ACCESS_KEY:-}" ]] && set_app_env "AWS_SECRET_ACCESS_KEY" "${AWS_SECRET_ACCESS_KEY}"
[[ -n "${DATABRICKS_HOST:-}" ]] && set_app_env "DATABRICKS_HOST" "${DATABRICKS_HOST}"
[[ -n "${DATABRICKS_TOKEN:-}" ]] && set_app_env "DATABRICKS_TOKEN" "${DATABRICKS_TOKEN}"
set_app_env "AWS_BUDGET_ALERT_EMAIL" "${AWS_BUDGET_ALERT_EMAIL- }"
[[ -n "${GOOGLE_CREDENTIALS:-}" ]] && set_app_env "GOOGLE_CREDENTIALS" "${GOOGLE_CREDENTIALS}"
[[ -n "${GOOGLE_PROJECT:-}" ]] && set_app_env "GOOGLE_PROJECT" "${GOOGLE_PROJECT}"
set_app_env "GCP_BUDGET_ALERT_EMAIL" "${GCP_BUDGET_ALERT_EMAIL- }"
set_app_env "AZURE_BUDGET_CONTACT_EMAIL" "${AZURE_BUDGET_CONTACT_EMAIL- }"
set_app_env "AZURE_BUDGET_WEBHOOK_URL" "${AZURE_BUDGET_WEBHOOK_URL- }"
[[ -n "${ARM_LOCATION:-}" ]] && set_app_env "ARM_LOCATION" "${ARM_LOCATION}"
[[ -n "${ARM_TENANT_ID:-}" ]] && set_app_env "ARM_TENANT_ID" "${ARM_TENANT_ID}"
[[ -n "${ARM_SUBSCRIPTION_ID:-}" ]] && set_app_env "ARM_SUBSCRIPTION_ID" "${ARM_SUBSCRIPTION_ID}"
[[ -n "${ARM_CLIENT_ID:-}" ]] && set_app_env "ARM_CLIENT_ID" "${ARM_CLIENT_ID}"
[[ -n "${ARM_CLIENT_SECRET:-}" ]] && set_app_env "ARM_CLIENT_SECRET" "${ARM_CLIENT_SECRET}"
[[ -n "${GSB_PROVISION_DEFAULTS:-}" ]] && set_app_env "GSB_PROVISION_DEFAULTS" "${GSB_PROVISION_DEFAULTS}"

for plan_var in \
  GSB_SERVICE_CSB_AWS_S3_BUCKET_PLANS \
  GSB_SERVICE_CSB_AWS_POSTGRESQL_PLANS \
  GSB_SERVICE_CSB_AWS_MYSQL_PLANS \
  GSB_SERVICE_CSB_AWS_REDIS_PLANS \
  GSB_SERVICE_CSB_AWS_SQS_PLANS \
  GSB_SERVICE_CSB_AWS_BEDROCK_PLANS \
  GSB_SERVICE_CSB_AWS_AURORA_POSTGRESQL_PLANS \
  GSB_SERVICE_CSB_AWS_AURORA_MYSQL_PLANS \
  GSB_SERVICE_CSB_AWS_MSSQL_PLANS \
  GSB_SERVICE_CSB_AWS_DYNAMODB_NAMESPACE_PLANS \
  GSB_SERVICE_CSB_GOOGLE_POSTGRES_PLANS \
  GSB_SERVICE_CSB_GOOGLE_MYSQL_PLANS \
  GSB_SERVICE_CSB_GOOGLE_STORAGE_BUCKET_PLANS \
  GSB_SERVICE_CSB_GOOGLE_VERTEX_AI_PLANS \
  GSB_SERVICE_CSB_AZURE_MONGODB_PLANS \
  GSB_SERVICE_CSB_AZURE_MSSQL_DB_PLANS \
  GSB_SERVICE_CSB_AZURE_MSSQL_DB_FAILOVER_GROUP_PLANS \
  GSB_SERVICE_CSB_AZURE_MSSQL_FOG_RUN_FAILOVER_PLANS \
  GSB_SERVICE_CSB_AZURE_REDIS_PLANS \
  GSB_SERVICE_CSB_AZURE_OPENAI_PLANS \
  GSB_SERVICE_CSB_DATABRICKS_MODEL_SERVING_PLANS; do
  val="${!plan_var:-}"
  [[ -n "${val}" ]] && set_app_env "${plan_var}" "${val}"
done

for managed_var in "${managed_optional_env_vars[@]}"; do
  if [[ -z "${!managed_var:-}" ]]; then
    ensure_cf_target
    cf unset-env "${APP_NAME}" "${managed_var}" >/dev/null 2>&1 || true
  fi
done

# ── Step B: bind MySQL backing DB ─────────────────────────────────────────────
echo "  → binding ${MYSQL_INST} to ${APP_NAME}..."
ensure_cf_target
cf bind-service "${APP_NAME}" "${MYSQL_INST}"

# ── Step C: extract DB credentials from VCAP_SERVICES → explicit env vars ────
# cloud.gov aws-rds provides VCAP_SERVICES in a format CSB doesn't auto-detect.
# We parse the binding and inject DB_HOST / DB_USERNAME / DB_PASSWORD etc.
echo "  → extracting DB credentials from VCAP_SERVICES binding..."
_VCAP_TMP=$(mktemp)
trap "rm -f $cfmf $_VCAP_TMP" EXIT
ensure_cf_target
cf env "${APP_NAME}" > "${_VCAP_TMP}" 2>&1

DB_HOST=$(python3 -c "
import sys, json, re
raw = open('${_VCAP_TMP}').read()
m = re.search(r'VCAP_SERVICES: (\{.+?\})\n\n', raw, re.DOTALL)
if not m: sys.exit(0)
try:
    v = json.loads(m.group(1))
    for svc in v.values():
        for inst in svc:
            c = inst.get('credentials', {})
            if 'host' in c: print(c['host']); sys.exit(0)
except Exception: pass
" 2>/dev/null || true)

DB_USERNAME=$(python3 -c "
import sys, json, re
raw = open('${_VCAP_TMP}').read()
m = re.search(r'VCAP_SERVICES: (\{.+?\})\n\n', raw, re.DOTALL)
if not m: sys.exit(0)
try:
    v = json.loads(m.group(1))
    for svc in v.values():
        for inst in svc:
            c = inst.get('credentials', {})
            if 'username' in c: print(c['username']); sys.exit(0)
except Exception: pass
" 2>/dev/null || true)

DB_PASSWORD=$(python3 -c "
import sys, json, re
raw = open('${_VCAP_TMP}').read()
m = re.search(r'VCAP_SERVICES: (\{.+?\})\n\n', raw, re.DOTALL)
if not m: sys.exit(0)
try:
    v = json.loads(m.group(1))
    for svc in v.values():
        for inst in svc:
            c = inst.get('credentials', {})
            if 'password' in c: print(c['password']); sys.exit(0)
except Exception: pass
" 2>/dev/null || true)

DB_PORT=$(python3 -c "
import sys, json, re
raw = open('${_VCAP_TMP}').read()
m = re.search(r'VCAP_SERVICES: (\{.+?\})\n\n', raw, re.DOTALL)
if not m: print('3306'); sys.exit(0)
try:
    v = json.loads(m.group(1))
    for svc in v.values():
        for inst in svc:
            c = inst.get('credentials', {})
            if 'port' in c: print(c['port']); sys.exit(0)
except Exception: pass
print('3306')
" 2>/dev/null || echo "3306")

DB_NAME=$(python3 -c "
import sys, json, re
raw = open('${_VCAP_TMP}').read()
m = re.search(r'VCAP_SERVICES: (\{.+?\})\n\n', raw, re.DOTALL)
if not m: print('servicebroker'); sys.exit(0)
try:
    v = json.loads(m.group(1))
    for svc in v.values():
        for inst in svc:
            c = inst.get('credentials', {})
            n = c.get('db_name') or c.get('name') or c.get('database', 'servicebroker')
            print(n); sys.exit(0)
except Exception: pass
print('servicebroker')
" 2>/dev/null || echo "servicebroker")

if [[ -z "${DB_HOST}" ]]; then
  echo "  ⚠ Could not auto-extract DB_HOST from VCAP_SERVICES."
  echo "    Falling back: run 'cf env ${APP_NAME}' and set DB_HOST/DB_USERNAME/DB_PASSWORD manually."
  echo "    Then: cf restage ${APP_NAME}"
else
  echo "  → setting DB env vars on ${APP_NAME} (host: ${DB_HOST})..."
  set_app_env DB_HOST "${DB_HOST}"
  set_app_env DB_USERNAME "${DB_USERNAME}"
  set_app_env DB_PASSWORD "${DB_PASSWORD}"
  set_app_env DB_PORT "${DB_PORT}"
  set_app_env DB_NAME "${DB_NAME}"
  set_app_env DB_TYPE "mysql"
fi

# ── Step D: start ─────────────────────────────────────────────────────────────
echo "  → starting ${APP_NAME}..."
ensure_cf_target
if ! cf start "${APP_NAME}"; then
  echo ""
  echo "  ✗ App failed to start. Recent logs:"
  cf logs "${APP_NAME}" --recent | tail -30
  exit 1
fi

# ── Step E: register service broker ──────────────────────────────────────────
ensure_cf_target
ROUTE=$(LANG=EN cf app "${APP_NAME}" | awk '/routes:/{print $2}')
echo "  → registering service broker '${BROKER_NAME}' at https://${ROUTE}..."
ensure_cf_target
cf create-service-broker "${BROKER_NAME}" \
  "${SECURITY_USER_NAME}" "${SECURITY_USER_PASSWORD}" \
  "https://${ROUTE}" \
  --space-scoped --update-if-exists

echo "  ✓ Broker '${BROKER_NAME}' registered."
