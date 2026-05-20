#!/usr/bin/env bash
# scripts/lib/compact-json-env.sh
#
# Compact all exported GSB_SERVICE_* and GSB_PROVISION_DEFAULTS variables to
# single-line JSON. Must be SOURCED (not executed) after loading a .env file.
#
# Why this is needed:
#   The brokerpak Makefiles prepend plan variables to every `go run` command
#   via BROKER_GO_OPTS, wrapping each value in single quotes. If a value
#   contains literal newlines the shell produces "unexpected EOF" errors.
#   This function strips all embedded newlines and collapses internal whitespace
#   so the values are safe to use in shell command prefixes.
#
# Usage:
#   source "$(dirname "$0")/lib/compact-json-env.sh"

_compact_json_exports() {
  local varname val
  local compacted

  if [[ -n "${GOOGLE_CREDENTIALS:-}" ]]; then
    export "GOOGLE_CREDENTIALS=$(COMPACT_JSON_VALUE="$GOOGLE_CREDENTIALS" python3 - <<'PY'
import json
import os
import re

raw = os.environ.get("COMPACT_JSON_VALUE", "").strip()

def normalize_private_key(value):
    return value.replace("\r\n", "\n").replace("\r", "\n")

try:
    payload = json.loads(raw)
except json.JSONDecodeError:
    match = re.search(r'"private_key"\s*:\s*"(.*?)"', raw, re.S)
    if not match:
        raise
    private_key = normalize_private_key(match.group(1)).replace("\n", r"\n")
    raw = raw[:match.start(1)] + private_key + raw[match.end(1):]
    payload = json.loads(raw)

if isinstance(payload.get("private_key"), str):
    payload["private_key"] = normalize_private_key(payload["private_key"])

print(json.dumps(payload, separators=(",", ":")))
PY
)"
  fi

  while IFS= read -r varname; do
    val="${!varname:-}"
    if [[ "$val" == *$'\n'* ]]; then
      compacted="${val//$'\n'/}"
      compacted="${compacted//$'\r'/}"
      compacted="${compacted//$'\t'/ }"
      export "$varname=$compacted"
    fi
  done < <(compgen -e | grep -E '^(GSB_SERVICE_.*|GSB_PROVISION_DEFAULTS)$')
}

_compact_json_exports
