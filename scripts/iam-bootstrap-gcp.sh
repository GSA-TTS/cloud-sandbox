#!/usr/bin/env bash
set -euo pipefail

# IAM bootstrap for GCP broker service account
# Creates a least-privileged service account for broker provisioning and outputs key for CI
# Usage: bash scripts/iam-bootstrap-gcp.sh <account-name> <project-id>

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <account-name> <project-id>" >&2
  exit 1
fi

ACCOUNT_NAME="$1"
PROJECT_ID="$2"

# Create service account
SA_EMAIL="$ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com"
gcloud iam service-accounts create "$ACCOUNT_NAME" --project="$PROJECT_ID" || true

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/aiplatform.user"

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectAdmin"

# Create and download key
KEY_FILE="gcp-service-account-key.json"
gcloud iam service-accounts keys create "$KEY_FILE" --iam-account="$SA_EMAIL" --project="$PROJECT_ID"

cat <<EOM

GCP service account created and key written to $KEY_FILE
To rotate, run:
  gcloud iam service-accounts keys create <new-key-file> --iam-account=$SA_EMAIL --project=$PROJECT_ID

To configure for CI, copy the key file path to gcp.env:
  GOOGLE_APPLICATION_CREDENTIALS=$(pwd)/$KEY_FILE
  GOOGLE_CLOUD_PROJECT=$PROJECT_ID

EOM
