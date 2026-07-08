#!/usr/bin/env bash
set -euo pipefail

# IAM bootstrap for Azure broker service principal
# Creates a least-privileged service principal for broker provisioning and outputs credentials for CI
# Usage: bash scripts/iam-bootstrap-azure.sh <app-name> <subscription-id>

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <app-name> <subscription-id>" >&2
  exit 1
fi

APP_NAME="$1"
SUBSCRIPTION_ID="$2"

# Create service principal
SP_JSON=$(az ad sp create-for-rbac --name "$APP_NAME" --role "Contributor" --scopes "/subscriptions/$SUBSCRIPTION_ID" --sdk-auth)

# Output to azure.env
cat > azure.env <<EOF
ARM_CLIENT_ID=$(echo "$SP_JSON" | jq -r '.clientId')
ARM_CLIENT_SECRET=$(echo "$SP_JSON" | jq -r '.clientSecret')
ARM_SUBSCRIPTION_ID=$(echo "$SP_JSON" | jq -r '.subscriptionId')
ARM_TENANT_ID=$(echo "$SP_JSON" | jq -r '.tenantId')
EOF

cat <<EOM

Azure service principal created and written to azure.env
To rotate, run:
  az ad sp credential reset --name $APP_NAME

To configure for CI, copy these values to azure.env.

EOM
