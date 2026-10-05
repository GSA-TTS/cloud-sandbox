#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "$script_dir/../.." && pwd)"
validator="$repo_root/scripts/validate-kubernetes-benchmark.sh"
fixtures="$repo_root/benchmark/fixtures"

bash -n "$validator" "$script_dir/test.sh"
node --check "$script_dir/validate.mjs"

bash "$validator" \
  "$fixtures/protocol.yaml" \
  "$fixtures/toolchain.lock.yaml" \
  "$fixtures/observations.ndjson"

invalid_output="$(mktemp)"
trap 'rm -f "$invalid_output"' EXIT
if bash "$validator" \
  "$fixtures/protocol.yaml" \
  "$fixtures/toolchain.lock.yaml" \
  "$fixtures/invalid-observations.ndjson" >"$invalid_output" 2>&1; then
  printf 'Expected invalid fixture validation to fail.\n' >&2
  exit 1
fi

for expected_error in \
  'service does not match provider' \
  'window_end must be later than window_start' \
  'tool version or checksum does not match toolchain lock'; do
  if ! grep -Fq "$expected_error" "$invalid_output"; then
    printf 'Missing expected validation error: %s\n' "$expected_error" >&2
    exit 1
  fi
done

printf 'Benchmark harness tests passed.\n'
