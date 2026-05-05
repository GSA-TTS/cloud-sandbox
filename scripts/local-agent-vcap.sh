#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: scripts/local-agent-vcap.sh [--normalized] <app-name> <service-instance> [service-label]

Binds a brokered service instance to an existing CF app, checks the app env for
the matching VCAP_SERVICES entry, and only restarts the app if the binding is
not visible yet.

Pass --normalized to print only the normalized binding payload when available.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

NORMALIZED_ONLY=0
if [[ "${1:-}" == "--normalized" ]]; then
  NORMALIZED_ONLY=1
  shift
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
const normalizedOnly = process.argv[4] === "1";
const vcap = env.system_env_json?.VCAP_SERVICES ?? {};

function parseJsonMaybe(value) {
  if (typeof value !== "string" || !value) {
    return null;
  }

  try {
    return JSON.parse(value);
  } catch {
    return null;
  }
}

function synthesizeNormalized(entry) {
  const credentials = entry?.credentials ?? {};
  const label = entry?.label ?? "";

  if (typeof credentials.normalized_binding_json === "string") {
    const parsed = parseJsonMaybe(credentials.normalized_binding_json);
    if (parsed) {
      return parsed;
    }
  }

  if (label === "csb-aws-bedrock") {
    return {
      version: "v1",
      provider: "aws",
      provisioner_family: "aws_bedrock_identity",
      connection_type: "runtime",
      endpoint: {
        base_url: credentials.bedrock_endpoint ?? null,
        region: credentials.region ?? null,
        api_version: null,
      },
      access: {
        mode: "aws_sigv4",
        expires_at: credentials.ttl_expires_at ?? null,
      },
      grant: {
        kind: "scoped_key",
        least_privilege_unit: "model",
        allowed_models: parseJsonMaybe(credentials.models) ?? [],
      },
      credential: {
        format: "aws_temp_creds",
        inline: {
          access_key_id: credentials.access_key_id ?? null,
          secret_access_key: credentials.secret_access_key ?? null,
        },
        secret_ref: null,
      },
    };
  }

  if (label === "csb-google-vertex-ai") {
    return {
      version: "v1",
      provider: "gcp",
      provisioner_family: "google_vertex_identity",
      connection_type: "runtime",
      endpoint: {
        base_url: credentials.api_endpoint ?? null,
        region: credentials.region ?? null,
        api_version: null,
      },
      access: {
        mode: "gcp_access_token",
        expires_at: credentials.ttl_expires_at ?? null,
      },
      grant: {
        kind: "service_account",
        least_privilege_unit: "project",
        allowed_models: parseJsonMaybe(credentials.models) ?? [],
      },
      credential: {
        format: "service_account_json",
        inline: {
          credentials_json: credentials.credentials_json ?? null,
        },
        secret_ref: null,
      },
    };
  }

  if (label === "csb-azure-openai") {
    const deployments = parseJsonMaybe(credentials.deployments) ?? [];
    return {
      version: "v1",
      provider: "azure",
      provisioner_family: "azure_openai_key",
      connection_type: "runtime",
      endpoint: {
        base_url: credentials.endpoint ?? null,
        region: null,
        api_version: credentials.api_version ?? null,
      },
      access: {
        mode: "api_key",
        expires_at: credentials.ttl_expires_at ?? null,
      },
      grant: {
        kind: "scoped_key",
        least_privilege_unit: "resource",
        allowed_models: deployments.map((deployment) => deployment?.model).filter(Boolean),
      },
      credential: {
        format: "api_key",
        inline: {
          api_key: credentials.api_key ?? null,
        },
        secret_ref: null,
      },
    };
  }

  return null;
}

function emit(entry) {
  if (!normalizedOnly) {
    console.log(JSON.stringify(entry, null, 2));
    return;
  }

  const normalized = synthesizeNormalized(entry);
  if (!normalized) {
    process.exit(3);
  }

  console.log(JSON.stringify(normalized, null, 2));
}

if (serviceLabel) {
  const selected = vcap[serviceLabel];
  if (!selected) {
    process.exit(2);
  }
  emit(selected[0]);
  process.exit(0);
}

for (const entries of Object.values(vcap)) {
  const match = entries.find((entry) =>
    entry?.name === targetInstance ||
    entry?.instance_name === targetInstance ||
    entry?.credentials?.instance_name === targetInstance,
  );
  if (match) {
    emit(match);
    process.exit(0);
  }
}

process.exit(2);
' "$env_json" "$SERVICE_INSTANCE" "$SERVICE_LABEL" "$NORMALIZED_ONLY"
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