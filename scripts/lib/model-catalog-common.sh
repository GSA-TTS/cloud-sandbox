#!/usr/bin/env bash

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: Required command not found: $cmd" >&2
    exit 1
  fi
}

timestamp_utc() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

slugify() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-'
}

load_env_file() {
  local env_file="$1"

  if [[ -f "$env_file" ]]; then
    # shellcheck source=/dev/null
    set -a; source "$env_file"; set +a
  fi
}

normalize_gcp_credentials_to_file() {
  local output_file="$1"

  if [[ -z "${GOOGLE_CREDENTIALS:-}" ]]; then
    echo "ERROR: GOOGLE_CREDENTIALS is not set; cannot create a temporary gcloud key file." >&2
    exit 1
  fi

  node - "${GOOGLE_CREDENTIALS}" "$output_file" <<'NODE'
const fs = require('fs');

const raw = process.argv[2];
const outputFile = process.argv[3];
const fixed = raw.replace(/"private_key": "([\s\S]*?)", "client_email"/, (_, key) => {
  return `"private_key": ${JSON.stringify(key)}, "client_email"`;
});

JSON.parse(fixed);
fs.writeFileSync(outputFile, fixed);
NODE
}

ensure_gcloud_adc_guidance() {
  local project_id="$1"

  cat >&2 <<EOF
ERROR: Could not authenticate gcloud for Model Garden catalog refresh.
Use one of these paths:
  1. Populate scripts/envs/gcp.env with GOOGLE_CREDENTIALS and GOOGLE_PROJECT.
  2. Or run:
     gcloud auth login --update-adc
     gcloud config set project "$project_id"
     gcloud auth application-default set-quota-project "$project_id"
EOF
  exit 1
}