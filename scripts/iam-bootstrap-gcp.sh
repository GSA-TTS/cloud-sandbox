#!/usr/bin/env bash
set -euo pipefail

# Create a GCP broker service-account key and securely write scripts/envs/gcp.env.
# The service account and its reviewed broker roles must already exist. This script
# never deploys a broker and never leaves a key file on disk.
# Usage: bash scripts/iam-bootstrap-gcp.sh <account-name> <project-id> <private-network-self-link>

umask 077
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_WRITER="$ROOT_DIR/scripts/lib/write-broker-env.py"
TEMPLATE="$ROOT_DIR/scripts/envs/gcp.env.example"
ENV_FILE="$ROOT_DIR/scripts/envs/gcp.env"

if [[ $# != 3 ]]; then
  echo "Usage: $0 <account-name> <project-id> <private-network-self-link>" >&2
  exit 1
fi

ACCOUNT_NAME="$1"
PROJECT_ID="$2"
AUTHORIZED_NETWORK_ID="$3"

SA_EMAIL="$ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
gcloud auth list --filter=status:ACTIVE --format='value(account)' | grep -qx '.\+' || {
  echo "ERROR: no active gcloud OAuth account. Run gcloud auth login first." >&2
  exit 1
}
gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" --format=json >/dev/null
expected_network="https://www.googleapis.com/compute/v1/projects/$PROJECT_ID/global/networks/"
[[ "$AUTHORIZED_NETWORK_ID" == "$expected_network"* ]] || {
  echo "ERROR: network must be a self-link in the target project." >&2
  exit 1
}
NETWORK_NAME="${AUTHORIZED_NETWORK_ID##*/}"
gcloud compute networks describe "$NETWORK_NAME" --project="$PROJECT_ID" --format=json >/dev/null
gcloud services vpc-peerings list --network="$NETWORK_NAME" --project="$PROJECT_ID" --format='value(service)' | grep -qx 'servicenetworking.googleapis.com' || {
  echo "ERROR: the selected network lacks an active Service Networking peering." >&2
  exit 1
}

key_file=$(mktemp)
trap 'rm -f "$key_file"' EXIT
gcloud iam service-accounts keys create "$key_file" --iam-account="$SA_EMAIL" --project="$PROJECT_ID" --quiet
GOOGLE_CREDENTIALS=$(jq -ce . "$key_file")
SECURITY_USER_PASSWORD=$(openssl rand -base64 48 | tr -d '\n/' | cut -c1-40)
GOOGLE_PROJECT="$PROJECT_ID"
GSB_PROVISION_DEFAULTS=$(printf '{"region":"us-central1","authorized_network_id":"%s"}' "$AUTHORIZED_NETWORK_ID")

export GOOGLE_CREDENTIALS GOOGLE_PROJECT GSB_PROVISION_DEFAULTS SECURITY_USER_PASSWORD
python3 "$ENV_WRITER" "$TEMPLATE" "$ENV_FILE" \
  GOOGLE_CREDENTIALS GOOGLE_PROJECT GSB_PROVISION_DEFAULTS SECURITY_USER_PASSWORD

echo "Wrote $ENV_FILE with mode 0600. No broker was deployed."
