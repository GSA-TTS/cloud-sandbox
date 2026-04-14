#!/usr/bin/env bash
# scripts/lib/patch-provider-display-name.sh
#
# Replaces `provider_display_name: VMware` with `provider_display_name: GSA TTS`
# in all brokerpak service definition YAMLs inside a given submodule directory.
#
# The upstream brokerpak repos ship with "VMware" as the provider_display_name
# because CSB was originally a VMware product. This patch corrects the CF
# marketplace metadata before the brokerpak ZIP is built by `make build`.
#
# Usage (source from a deploy script, with SUBMODULE already set):
#   source "${SCRIPT_DIR}/lib/patch-provider-display-name.sh"
#
# Idempotent: safe to re-run (no-op if already patched).
# Submodule reset: `git -C "${SUBMODULE}" checkout -- '*.yml'` will undo this.
# ─────────────────────────────────────────────────────────────────────────────

_PROVIDER_DISPLAY_NAME="${PROVIDER_DISPLAY_NAME:-GSA TTS}"

echo "==> [pre-build] Patching provider_display_name: VMware → '${_PROVIDER_DISPLAY_NAME}' in $(basename "${SUBMODULE}") YAMLs..."

_patched=0
while IFS= read -r -d '' _yml; do
  if grep -q "provider_display_name: VMware" "${_yml}"; then
    sed -i.bak "s/provider_display_name: VMware/provider_display_name: ${_PROVIDER_DISPLAY_NAME}/g" "${_yml}"
    rm -f "${_yml}.bak"
    (( _patched++ )) || true
  fi
done < <(find "${SUBMODULE}" -maxdepth 1 -name "*.yml" -print0)

if [[ "${_patched}" -gt 0 ]]; then
  echo "     Patched ${_patched} file(s)."
else
  echo "     Nothing to patch (already up to date)."
fi

unset _PROVIDER_DISPLAY_NAME _patched _yml
