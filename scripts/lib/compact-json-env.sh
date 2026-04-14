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
  while IFS= read -r varname; do
    val="${!varname:-}"
    # Only process if the value actually contains a newline or is a known JSON var
    if [[ "$val" == *$'\n'* ]]; then
      export "$varname=$(printf '%s' "$val" | tr -d '\n\r' | tr -s '\t' ' ')"
    fi
  done < <(compgen -e | grep -E '^(GSB_SERVICE_|GSB_PROVISION_DEFAULTS|GOOGLE_CREDENTIALS)')
}

_compact_json_exports
