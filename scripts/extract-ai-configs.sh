#!/usr/bin/env bash

# Extract valid AI API configurations for Zed and OpenCode
# Usage: bash scripts/extract-ai-configs.sh [SCRATCH_APP_NAME]
# Default scratch app: scratch-app

set -euo pipefail

SCRATCH_APP="${1:-scratch-app}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

# Verified instance names (update these if instances change)
declare -A INSTANCES=(
    [bedrock]="verify-bedrock-0505"
    [vertex]="verify-vertex-0505"
    [gemini]="verify-gemini-0505b"
    [azure]="verify-openai-eastus2-0511095227"
    [foundry]="verify-foundry-0505c"
)

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}ℹ${NC} $*" >&2; }
log_ok() { echo -e "${GREEN}✓${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*" >&2; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

# Extract binding from CF
get_binding() {
    local app=$1 instance=$2 normalized=${3:-false}

    if [[ "$normalized" == "true" ]]; then
        bash scripts/local-agent-vcap.sh --normalized "$app" "$instance" 2>/dev/null || echo ""
    else
        bash scripts/local-agent-vcap.sh "$app" "$instance" 2>/dev/null || echo ""
    fi
}

# Export AWS Bedrock env vars for Zed
export_bedrock_env() {
    local instance=${INSTANCES[bedrock]}
    log_info "Extracting AWS Bedrock credentials..."

    local binding=$(get_binding "$SCRATCH_APP" "$instance" true)
    if [[ -z "$binding" ]]; then
        log_error "Failed to extract Bedrock binding"
        return 1
    fi

    local access_key=$(printf '%s' "$binding" | jq -r '.credential.inline.access_key_id // empty')
    local secret_key=$(printf '%s' "$binding" | jq -r '.credential.inline.secret_access_key // empty')
    local region=$(printf '%s' "$binding" | jq -r '.endpoint.region // empty')

    if [[ -z "$access_key" || -z "$secret_key" || -z "$region" ]]; then
        log_error "Missing Bedrock credentials"
        return 1
    fi

    cat <<EOF
# AWS Bedrock for Zed / OpenCode
export AWS_ACCESS_KEY_ID='$access_key'
export AWS_SECRET_ACCESS_KEY='$secret_key'
export AWS_REGION='$region'

# Available models:
# $(printf '%s' "$binding" | jq -r '.grant.allowed_models[] // empty' | head -n 3 | sed 's/^/# /')
EOF

    log_ok "Bedrock: $region ($access_key...)"
}

# Export GCP Vertex AI env vars for Zed
export_vertex_env() {
    local instance=${INSTANCES[vertex]}
    log_info "Extracting GCP Vertex credentials..."

    local binding=$(get_binding "$SCRATCH_APP" "$instance" true)
    if [[ -z "$binding" ]]; then
        log_error "Failed to extract Vertex binding"
        return 1
    fi

    local creds_json=$(printf '%s' "$binding" | jq -r '.credential.inline.credentials_json // empty')
    local region=$(printf '%s' "$binding" | jq -r '.endpoint.region // empty')

    if [[ -z "$creds_json" || -z "$region" ]]; then
        log_error "Missing Vertex credentials"
        return 1
    fi

    local project=$(printf '%s' "$creds_json" | jq -r 'fromjson | .project_id // empty')

    cat <<EOF
# GCP Vertex AI for Zed / OpenCode
export GOOGLE_APPLICATION_CREDENTIALS_JSON='$creds_json'
export GOOGLE_CLOUD_PROJECT='$project'
export VERTEX_LOCATION='$region'

# Available models:
# $(printf '%s' "$binding" | jq -r '.grant.allowed_models[] // empty' | head -n 3 | sed 's/^/# /')
EOF

    log_ok "Vertex: $project/$region ($project...)"
}

# Export GCP Gemini API key for Zed
export_gemini_env() {
    local instance=${INSTANCES[gemini]}
    log_info "Extracting GCP Gemini API credentials..."

    local binding=$(get_binding "$SCRATCH_APP" "$instance" true)
    if [[ -z "$binding" ]]; then
        log_error "Failed to extract Gemini binding"
        return 1
    fi

    local api_key=$(printf '%s' "$binding" | jq -r '.credential.inline.api_key // empty')

    if [[ -z "$api_key" ]]; then
        log_error "Missing Gemini API key"
        return 1
    fi

    cat <<EOF
# GCP Gemini API for Zed / OpenCode
export GEMINI_API_KEY='$api_key'

# Available models:
# $(printf '%s' "$binding" | jq -r '.grant.allowed_models[] // empty' | head -n 3 | sed 's/^/# /')
EOF

    log_ok "Gemini: API key found (${api_key:0:10}...)"
}

# Export Azure OpenAI env vars for Zed
export_azure_env() {
    local instance=${INSTANCES[azure]}
    log_info "Extracting Azure OpenAI credentials..."

    local binding=$(get_binding "$SCRATCH_APP" "$instance" false)
    if [[ -z "$binding" ]]; then
        log_error "Failed to extract Azure OpenAI binding"
        return 1
    fi

    local endpoint=$(printf '%s' "$binding" | jq -r '.credentials.endpoint // empty')
    local api_key=$(printf '%s' "$binding" | jq -r '.credentials.api_key // empty')
    local api_version=$(printf '%s' "$binding" | jq -r '.credentials.api_version // empty')

    if [[ -z "$endpoint" || -z "$api_key" || -z "$api_version" ]]; then
        log_error "Missing Azure OpenAI credentials"
        return 1
    fi

    local deployments=$(printf '%s' "$binding" | jq -r '.credentials.deployments | fromjson | .[0].name // empty')

    cat <<EOF
# Azure OpenAI for Zed / OpenCode
export AZURE_OPENAI_API_KEY='$api_key'
export AZURE_OPENAI_ENDPOINT='$endpoint'
export AZURE_OPENAI_API_VERSION='$api_version'

# Available deployments: $deployments
EOF

    log_ok "Azure OpenAI: $(echo "$endpoint" | awk -F'/' '{print $(NF-2)}')"
}

# Export Azure Foundry env vars for Zed
export_foundry_env() {
    local instance=${INSTANCES[foundry]}
    log_info "Extracting Azure Foundry credentials..."

    local binding=$(get_binding "$SCRATCH_APP" "$instance" true)
    if [[ -z "$binding" ]]; then
        log_error "Failed to extract Foundry binding"
        return 1
    fi

    local endpoint=$(printf '%s' "$binding" | jq -r '.endpoint.base_url // empty')
    local api_key=$(printf '%s' "$binding" | jq -r '.credential.inline.api_key // empty')
    local deployment=$(printf '%s' "$binding" | jq -r '.credential.inline.deployment_name // empty')

    if [[ -z "$endpoint" || -z "$api_key" || -z "$deployment" ]]; then
        log_error "Missing Foundry credentials"
        return 1
    fi

    cat <<EOF
# Azure Foundry for Zed / OpenCode
export FOUNDRY_OPENAI_API_KEY='$api_key'
export FOUNDRY_OPENAI_API_BASE='$endpoint'
export FOUNDRY_OPENAI_API_VERSION='2024-02-01'
export FOUNDRY_MODEL_NAME='$deployment'
export FOUNDRY_DEPLOYMENT_NAME='$deployment'

# Note: Current deployment is embedding-only ($deployment)
EOF

    log_ok "Foundry: $deployment ($endpoint)"
}

main() {
    log_info "Extracting AI API configurations for Zed & OpenCode"
    log_info "Scratch app: $SCRATCH_APP"
    echo ""

    # Check CF auth
    if ! cf target >/dev/null 2>&1; then
        log_error "Not authenticated with Cloud Foundry. Run: cf login -a api.fr.cloud.gov --sso"
        return 1
    fi

    # Check scratch app exists
    if ! cf service "$SCRATCH_APP" >/dev/null 2>&1; then
        log_warn "Scratch app '$SCRATCH_APP' not found. Service instances must still be bound manually."
    fi

    # Extract all configs
    local temp_file
    temp_file=$(mktemp)
    local configs_found=0

    {
        echo "#!/usr/bin/env bash"
        echo "# Extracted AI API configurations - $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "# Usage: source <(bash scripts/extract-ai-configs.sh)"
        echo ""
    } > "$temp_file"

    for provider in bedrock vertex gemini azure foundry; do
        if output=$(export_${provider}_env 2>/dev/null); then
            printf '%s\n' "$output" >> "$temp_file"
            ((configs_found++)) || true
        fi
        echo "" >> "$temp_file"
    done

    cat "$temp_file"

    echo ""
    if [[ $configs_found -gt 0 ]]; then
        log_ok "Extracted $configs_found provider configurations"
        log_info "To use these env vars, run: source <(bash scripts/extract-ai-configs.sh)"
    else
        log_error "Failed to extract any configurations"
        return 1
    fi

    # Show model counts
    echo ""
    log_info "Model availability summary:"

    for provider in bedrock vertex gemini; do
        instance=${INSTANCES[$provider]}
        binding=$(get_binding "$SCRATCH_APP" "$instance" true 2>/dev/null || echo "")
        if [[ -n "$binding" ]]; then
            count=$(printf '%s' "$binding" | jq '.grant.allowed_models | length // 0')
            log_ok "$provider: $count models"
        fi
    done

    # Show Zed config snippet
    echo ""
    echo -e "${BLUE}── Zed Config Snippet${NC}"
    cat <<EOF
Add to ~/.config/zed/settings.json:

{
  "assistant": {
    "default_model": {
      "provider": "openai",
      "model": "gpt-5-4-mini"
    }
  }
}

Then set these env vars before launching Zed:
  export OPENAI_API_KEY=\$AZURE_OPENAI_API_KEY
  export OPENAI_API_BASE=\$AZURE_OPENAI_ENDPOINT/openai/v1
EOF

    # Show OpenCode usage
    echo ""
    echo -e "${BLUE}── OpenCode Usage${NC}"
    cat <<EOF
Launch unified multi-provider session:
  bash scripts/launch-opencode-broker-session.sh

Then test models:
  opencode models sandbox-azure-openai
  opencode run --model sandbox-azure-openai/gpt-5-4-mini "hello"
  opencode run --model sandbox-gemini/gemini-2.5-flash "hello"
  opencode run --model amazon-bedrock/anthropic.claude-opus-4-1-20250805 "hello"
EOF
}

main "$@"
