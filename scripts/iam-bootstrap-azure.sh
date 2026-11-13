#!/usr/bin/env bash
set -euo pipefail

# Validate a pre-approved existing Azure broker identity and resource-group scope.
# It intentionally does not create principals, reset credentials, assign roles, or
# write an environment file. Those mutations require a catalog-specific approval.
# Usage: bash scripts/iam-bootstrap-azure.sh <existing-app-name> <subscription-id> <approved-resource-group>

umask 077
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_WRITER="$ROOT_DIR/scripts/lib/write-broker-env.py"
TEMPLATE="$ROOT_DIR/scripts/envs/azure.env.example"
ENV_FILE="$ROOT_DIR/scripts/envs/azure.env"

if [[ $# != 3 ]]; then
  echo "Usage: $0 <existing-app-name> <subscription-id> <approved-resource-group>" >&2
  exit 1
fi

APP_NAME="$1"
SUBSCRIPTION_ID="$2"
RESOURCE_GROUP="$3"

az account set --subscription "$SUBSCRIPTION_ID"
existing_app_id=$(az ad sp list --display-name "$APP_NAME" --query '[?displayName==`'"$APP_NAME"'`].appId | [0]' --output tsv)
[[ -n "$existing_app_id" ]] || { echo "ERROR: approved broker identity does not exist; refusing to create one." >&2; exit 1; }
az group show --name "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" --output none
object_id=$(az ad sp show --id "$existing_app_id" --query id --output tsv)
scope="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
az role assignment list --assignee-object-id "$object_id" --scope "$scope" --query '[].roleDefinitionName' --output tsv | grep -qx 'Contributor' || {
  echo "ERROR: the existing identity lacks Contributor at the approved resource-group scope." >&2
  exit 1
}
echo "Azure identity and resource-group scope validated. No credential, role, or broker changes were made."
