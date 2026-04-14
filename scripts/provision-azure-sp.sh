#!/usr/bin/env bash
# provision-azure-sp.sh — Create Azure SP, update azure.env, deploy csb-azure
#
# Prerequisites:
#   az login --use-device-code
#   export AZURE_SUBSCRIPTION_ID=<your-subscription-id>
#   export AZURE_TENANT_ID=<your-tenant-id>      # optional — uses current login tenant if unset
#
# Or set them in your shell before running this script.
set -euo pipefail

SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:?Set AZURE_SUBSCRIPTION_ID before running this script}"
TENANT_ID="${AZURE_TENANT_ID:-$(az account show --query tenantId --output tsv)}"
SP_NAME=csb-sandbox-broker
ENV_FILE=scripts/envs/azure.env

az account set --subscription "$SUBSCRIPTION_ID"
echo "==> [1/4] Creating service principal '$SP_NAME'..."

# Idempotent: reset if already exists
if az ad sp show --id "http://$SP_NAME" &>/dev/null 2>&1; then
  echo "    SP already exists — resetting credentials..."
  SP_JSON=$(az ad sp credential reset \
    --id "http://$SP_NAME" --output json 2>&1)
else
  SP_JSON=$(az ad sp create-for-rbac \
    --name "$SP_NAME" \
    --role Contributor \
    --scopes "/subscriptions/$SUBSCRIPTION_ID" \
    --output json 2>&1)
fi

CLIENT_ID=$(echo "$SP_JSON"     | python3 -c "import sys,json; print(json.load(sys.stdin)['appId'])")
CLIENT_SECRET=$(echo "$SP_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin)['password'])")

echo "    Client ID : $CLIENT_ID"
echo "    Secret    : <set>"

echo "==> [2/4] Assigning User Access Administrator role..."
OBJECT_ID=$(az ad sp show --id "$CLIENT_ID" --query id --output tsv 2>&1)
az role assignment create \
  --assignee-object-id "$OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --output none 2>&1 || echo "    (role may already exist — continuing)"

echo "==> [3/4] Writing credentials to $ENV_FILE..."
PASS=$(python3 -c "import secrets,string; print(''.join(secrets.choice(string.ascii_letters+string.digits) for _ in range(40)))")

python3 - "$TENANT_ID" "$SUBSCRIPTION_ID" "$CLIENT_ID" "$CLIENT_SECRET" "$PASS" "$ENV_FILE" << 'PYEOF'
import sys, re
tenant_id, sub_id, client_id, client_secret, broker_pass, path = sys.argv[1:]
with open(path) as f:
    content = f.read()
content = re.sub(r'^ARM_TENANT_ID=.*$',       f'ARM_TENANT_ID={tenant_id}',       content, flags=re.MULTILINE)
content = re.sub(r'^ARM_SUBSCRIPTION_ID=.*$', f'ARM_SUBSCRIPTION_ID={sub_id}',    content, flags=re.MULTILINE)
content = re.sub(r'^ARM_CLIENT_ID=.*$',       f'ARM_CLIENT_ID={client_id}',       content, flags=re.MULTILINE)
content = re.sub(r'^ARM_CLIENT_SECRET=.*$',   f'ARM_CLIENT_SECRET={client_secret}',content, flags=re.MULTILINE)
content = re.sub(r'^SECURITY_USER_PASSWORD=.*$', f'SECURITY_USER_PASSWORD={broker_pass}', content, flags=re.MULTILINE)
with open(path, 'w') as f:
    f.write(content)
print(f"Written: ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, SECURITY_USER_PASSWORD")
PYEOF

echo "==> [4/4] Deploying csb-azure broker..."
cd "$(dirname "$0")/.."
pnpm run broker:deploy:azure 2>&1
