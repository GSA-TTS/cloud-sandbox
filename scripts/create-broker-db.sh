#!/usr/bin/env bash
# scripts/create-broker-db.sh
#
# Creates the MySQL backing database for CSB brokers in the current CF space.
# Uses the cloud.gov aws-rds micro-mysql plan (available in gsa-tts-iae-lava-beds/dev).
#
# Usage:
#   ./scripts/create-broker-db.sh [instance-name]
#
# Defaults to instance name: csb-sql
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

INSTANCE_NAME="${1:-csb-sql}"
OFFERING="aws-rds"
PLAN="micro-mysql"

echo "→ Checking CF authentication..."
cf target > /dev/null 2>&1 || { echo "ERROR: Not logged in to CF. Run: cf login -a api.fr.cloud.gov --sso"; exit 1; }

CF_ORG=$(cf target | awk '/org:/{print $2}')
CF_SPACE=$(cf target | awk '/space:/{print $2}')
echo "→ CF target: org=${CF_ORG}  space=${CF_SPACE}"

# Check if instance already exists
if cf service "${INSTANCE_NAME}" > /dev/null 2>&1; then
  # Collapse the full "Showing status of last operation" block into one line for matching
  FULL_STATUS=$(cf service "${INSTANCE_NAME}" | tr '\n' ' ')
  if echo "$FULL_STATUS" | grep -q "create succeeded"; then
    echo "✓ Service instance '${INSTANCE_NAME}' already exists (create succeeded). Skipping creation."
    exit 0
  elif echo "$FULL_STATUS" | grep -q "create failed"; then
    echo "ERROR: Existing instance '${INSTANCE_NAME}' is in a failed state. Delete it first:"
    echo "       cf delete-service ${INSTANCE_NAME} -f"
    exit 1
  else
    echo "ℹ Service instance '${INSTANCE_NAME}' exists but status is unclear — continuing to wait..."
  fi
fi

echo "→ Creating MySQL backing database '${INSTANCE_NAME}' using ${OFFERING}/${PLAN}..."
cf create-service "${OFFERING}" "${PLAN}" "${INSTANCE_NAME}" \
  -c '{"storage_gb": 5}'

echo "→ Waiting for '${INSTANCE_NAME}' to become ready (this may take several minutes)..."
while true; do
  # "status:" line reads "create succeeded", "create in progress", "create failed", etc.
  STATUS_LINE=$(cf service "${INSTANCE_NAME}" | awk '/status:/{$1=""; print $0}' | xargs)
  case "${STATUS_LINE}" in
    *succeeded*)
      echo "✓ '${INSTANCE_NAME}' is ready."
      break
      ;;
    *failed*)
      echo "ERROR: Service creation failed."
      cf service "${INSTANCE_NAME}"
      exit 1
      ;;
    *)
      echo "  status: ${STATUS_LINE} — polling again in 15s..."
      sleep 15
      ;;
  esac
done
