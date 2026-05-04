#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/local-agent-vcap.sh <app-name> <service-instance> [service-label]

Binds a brokered service instance to an existing CF app, checks the app env for
the matching VCAP_SERVICES entry, and only restarts the app if the binding is
not visible yet.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

APP_NAME=${1:-}
SERVICE_INSTANCE=${2:-}
SERVICE_LABEL=${3:-}

if [[ -z "$APP_NAME" || -z "$SERVICE_INSTANCE" ]]; then
  usage >&2
  exit 1
fi

print_matching_vcap() {
  local env_json=$1

  node -e '
const env = JSON.parse(process.argv[1]);
const targetInstance = process.argv[2];
const serviceLabel = process.argv[3];
const vcap = env.system_env_json?.VCAP_SERVICES ?? {};

if (serviceLabel) {
  const selected = vcap[serviceLabel];
  if (!selected) {
    process.exit(2);
  }
  console.log(JSON.stringify(selected, null, 2));
  process.exit(0);
}

for (const entries of Object.values(vcap)) {
  const match = entries.find((entry) =>
    entry?.name === targetInstance ||
    entry?.instance_name === targetInstance ||
    entry?.credentials?.instance_name === targetInstance,
  );
  if (match) {
    console.log(JSON.stringify(match, null, 2));
    process.exit(0);
  }
}

process.exit(2);
' "$env_json" "$SERVICE_INSTANCE" "$SERVICE_LABEL"
}

bind_output=""
if ! bind_output=$(cf bind-service "$APP_NAME" "$SERVICE_INSTANCE" 2>&1); then
  if [[ "$bind_output" == *"already exists"* ]]; then
    printf 'Binding already exists for %s -> %s\n' "$APP_NAME" "$SERVICE_INSTANCE" >&2
  else
    printf '%s\n' "$bind_output" >&2
    exit 1
  fi
else
  printf '%s\n' "$bind_output" >&2
fi

app_guid=$(cf app "$APP_NAME" --guid)
env_json=$(cf curl "/v3/apps/${app_guid}/env")

if print_matching_vcap "$env_json"; then
  exit 0
fi

printf 'Current app env does not include %s yet; restarting %s to refresh VCAP_SERVICES...\n' "$SERVICE_INSTANCE" "$APP_NAME" >&2
cf restart "$APP_NAME" >&2

env_json=$(cf curl "/v3/apps/${app_guid}/env")

if print_matching_vcap "$env_json"; then
  exit 0
fi

node -e '
const env = JSON.parse(process.argv[1]);
const serviceLabel = process.argv[2];
const vcap = env.system_env_json?.VCAP_SERVICES ?? {};

if (serviceLabel) {
  console.error(`No VCAP_SERVICES entry found for label: ${serviceLabel}`);
} else {
  console.error(`No VCAP_SERVICES entry found for instance: ${process.argv[3]}`);
}

console.log(JSON.stringify(vcap, null, 2));
process.exit(1);
' "$env_json" "$SERVICE_LABEL" "$SERVICE_INSTANCE"