#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  printf 'Usage: %s <protocol.yaml> <toolchain.lock.yaml> <observations.ndjson>\n' "$0" >&2
  exit 2
fi

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

exec node "$repo_root/benchmark/scripts/validate.mjs" "$1" "$2" "$3"
