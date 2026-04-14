#!/usr/bin/env bash
# scripts/teardown-broker.sh
#
# Deregisters a CSB broker and deletes its CF app.
# Does NOT delete any provisioned service instances — deprovision those first.
#
# Usage:
#   ./scripts/teardown-broker.sh <broker-name> <app-name>
#
# Examples:
#   ./scripts/teardown-broker.sh csb-aws-sandbox csb-aws
#   ./scripts/teardown-broker.sh csb-gcp-sandbox csb-gcp
#   ./scripts/teardown-broker.sh csb-azure-sandbox csb-azure
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

BROKER_NAME="${1:-}"
APP_NAME="${2:-}"

if [[ -z "${BROKER_NAME}" || -z "${APP_NAME}" ]]; then
  echo "Usage: $0 <broker-name> <app-name>"
  echo "  broker-name  e.g. csb-aws-sandbox"
  echo "  app-name     e.g. csb-aws"
  exit 1
fi

cf target > /dev/null 2>&1 || {
  echo "ERROR: Not logged in to CF. Run: cf login -a api.fr.cloud.gov --sso"
  exit 1
}

echo "⚠️  This will deregister broker '${BROKER_NAME}' and delete app '${APP_NAME}'."
echo "    Any bound service instances will lose their broker — deprovision them first."
read -r -p "Continue? [y/N] " confirm
[[ "${confirm}" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo "→ Deregistering service broker '${BROKER_NAME}'..."
cf delete-service-broker "${BROKER_NAME}" -f || echo "  (broker not registered — skipping)"

echo "→ Deleting CF app '${APP_NAME}'..."
cf delete "${APP_NAME}" -f -r || echo "  (app not found — skipping)"

echo "✓ Teardown of '${BROKER_NAME}' complete."
echo ""
echo "  The csb-sql backing database was NOT deleted. To remove it:"
echo "    cf delete-service csb-sql -f"
