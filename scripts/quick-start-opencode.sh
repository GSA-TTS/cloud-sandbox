#!/usr/bin/env bash

# Quick-Start: OpenCode with Broker-Backed AI Models
# Usage: bash scripts/quick-start-opencode.sh [COMMAND] [ARGS...]
# Commands: list, run, chat, validate

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

COMMAND="${1:-list}"
shift || true

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ${NC} $*" >&2; }
log_ok() { echo -e "${GREEN}✓${NC} $*" >&2; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*" >&2; }
log_error() { echo -e "${RED}✗${NC} $*" >&2; }

# Launch unified session
start_session() {
    log_info "Launching unified multi-provider OpenCode session..."
    bash scripts/launch-opencode-broker-session.sh "$@"
}

# List available models per provider
list_models() {
    log_info "Available models by provider:"
    echo ""

    if ! command -v opencode &>/dev/null; then
        log_error "opencode not found. Install with: brew install opencode"
        return 1
    fi

    local providers=(
        "amazon-bedrock"
        "google-vertex"
        "sandbox-gemini"
        "sandbox-azure-openai"
        "sandbox-foundry"
    )

    for provider in "${providers[@]}"; do
        local count=0
        if output=$(opencode models "$provider" 2>/dev/null | grep -c "^" || echo "0"); then
            count=$output
        fi

        case "$provider" in
            amazon-bedrock)
                echo -e "  ${CYAN}AWS Bedrock${NC}         ($provider): $count models"
                ;;
            google-vertex)
                echo -e "  ${CYAN}GCP Vertex${NC}          ($provider): $count models"
                ;;
            sandbox-gemini)
                echo -e "  ${CYAN}GCP Gemini${NC}          ($provider): $count models ⭐ (most working)"
                ;;
            sandbox-azure-openai)
                echo -e "  ${CYAN}Azure OpenAI${NC}        ($provider): $count models"
                ;;
            sandbox-foundry)
                echo -e "  ${CYAN}Azure Foundry${NC}       ($provider): $count models"
                ;;
        esac
    done

    echo ""
    log_ok "Full session: bash scripts/quick-start-opencode.sh run"
}

# Test a single model
test_model() {
    local model="${1:-sandbox-azure-openai/gpt-5-4-mini}"

    log_info "Testing: $model"

    start_session run --model "$model" "hello"
}

# Interactive chat with a model
chat_model() {
    local model="${1:-sandbox-gemini/gemini-2.5-flash}"

    log_info "Launching interactive chat with $model"
    log_info "Type 'exit' or Ctrl+D to quit"
    echo ""

    start_session run --model "$model"
}

# Validate all broker models
validate_all() {
    log_info "Running comprehensive OpenCode validation (may take 2-5 minutes)..."
    echo ""

    if ! command -v opencode &>/dev/null; then
        log_error "opencode not found. Install with: brew install opencode"
        return 1
    fi

    bash scripts/validate-opencode-broker-models.sh

    echo ""
    log_ok "Validation report saved to: .cache/opencode-validations/"

    # Show summary
    local latest_report=$(ls -t .cache/opencode-validations/opencode-broker-validation-*.json 2>/dev/null | head -n 1)
    if [[ -f "$latest_report" ]]; then
        local passed=$(jq '.results | map(select(.run_status=="passed")) | length' "$latest_report")
        local failed=$(jq '.results | map(select(.run_status=="failed")) | length' "$latest_report")
        local unsupported=$(jq '.results | map(select(.run_status=="unsupported")) | length' "$latest_report")

        echo ""
        echo -e "  ${GREEN}Passed${NC}:       $passed models ✓"
        echo -e "  ${RED}Failed${NC}:       $failed models ✗"
        echo -e "  ${YELLOW}Unsupported${NC}:  $unsupported models"
    fi
}

# Show help
show_help() {
    cat <<EOF
${BLUE}Cloud Sandbox — OpenCode Quick-Start${NC}

Usage: bash scripts/quick-start-opencode.sh [COMMAND] [ARGS]

Commands:

  ${CYAN}list${NC}
    List available models per provider

  ${CYAN}run [MODEL]${NC}
    Run single test with a model
    Default model: sandbox-azure-openai/gpt-5-4-mini
    Examples:
      bash scripts/quick-start-opencode.sh run sandbox-gemini/gemini-2.5-flash
      bash scripts/quick-start-opencode.sh run amazon-bedrock/openai.gpt-oss-120b-1:0

  ${CYAN}chat [MODEL]${NC}
    Interactive chat session
    Default model: sandbox-gemini/gemini-2.5-flash
    Examples:
      bash scripts/quick-start-opencode.sh chat sandbox-azure-openai/gpt-5-4-mini
      bash scripts/quick-start-opencode.sh chat

  ${CYAN}validate${NC}
    Run full broker validation suite
    Tests all 60+ models across all 5 providers
    (takes 2-5 minutes)

  ${CYAN}models [PROVIDER]${NC}
    List models for a specific provider
    Valid providers: amazon-bedrock, google-vertex, sandbox-gemini,
                    sandbox-azure-openai, sandbox-foundry

  ${CYAN}env${NC}
    Print env vars needed for OpenCode session

  ${CYAN}help${NC}
    Show this help message

Examples:

  ${YELLOW}# Quick test with Gemini (most reliable)${NC}
  bash scripts/quick-start-opencode.sh run sandbox-gemini/gemini-2.5-flash

  ${YELLOW}# Interactive chat with Azure OpenAI${NC}
  bash scripts/quick-start-opencode.sh chat sandbox-azure-openai/gpt-5-4-mini

  ${YELLOW}# List available Azure OpenAI models${NC}
  opencode models sandbox-azure-openai

  ${YELLOW}# Full validation sweep${NC}
  bash scripts/quick-start-opencode.sh validate

  ${YELLOW}# Test multiple providers in parallel${NC}
  for model in sandbox-gemini/gemini-2.5-flash sandbox-azure-openai/gpt-5-4-mini; do
    bash scripts/quick-start-opencode.sh run "\$model" &
  done
  wait

Status of Validated Models:

  ${GREEN}✓ 27 Passing${NC}
    - sandbox-gemini/*           (19 models) ⭐ ${CYAN}RECOMMENDED${NC}
    - sandbox-azure-openai/*     (4 models)
    - amazon-bedrock/*           (2 models) — IAM issues
    - google-vertex/*            (2 models) — RBAC issues

  ${RED}✗ 26 Failing${NC}
    - amazon-bedrock/*           (25 models) — bedrock:InvokeModel permission denied
    - google-vertex/*            (1 model) — project access restrictions

  ${YELLOW}⚠ 9 Unsupported/Not Listed${NC}
    - Foundry                    (embedding-only, not chat-capable yet)
    - Some Bedrock models        (not in OpenCode catalog)

For details, see:
  docs/ai-api-working-models.md
  docs/ai-api-config-extraction.md
  .cache/opencode-validations/ (validation reports)

EOF
}

# Show env vars needed
show_env() {
    log_info "Environment variables needed for OpenCode session:"
    echo ""

    log_ok "These are set automatically by scripts/launch-opencode-broker-session.sh"
    log_info "If setting manually, extract from CF bindings:"

    cat <<EOF

  # AWS Bedrock
  export AWS_ACCESS_KEY_ID='...'
  export AWS_SECRET_ACCESS_KEY='...'
  export AWS_REGION='us-east-1'

  # GCP Vertex
  export GOOGLE_APPLICATION_CREDENTIALS='~/.config/gcloud/vertex-sandbox.json'
  export GOOGLE_CLOUD_PROJECT='project-id'
  export VERTEX_LOCATION='us-central1'

  # GCP Gemini
  export GEMINI_API_KEY='...'

  # Azure OpenAI
  export AZURE_OPENAI_API_KEY='...'
  export AZURE_OPENAI_ENDPOINT='https://...openai.azure.com/'
  export AZURE_OPENAI_API_VERSION='2024-08-01-preview'

  # Azure Foundry
  export FOUNDRY_OPENAI_API_KEY='...'
  export FOUNDRY_OPENAI_API_BASE='https://...openai.azure.com/'

EOF

    echo ""
    log_info "Or use the extraction script:"
    echo "  source <(bash scripts/extract-ai-configs.sh)"
}

main() {
    case "$COMMAND" in
        list)
            list_models
            ;;
        run)
            test_model "${1:-sandbox-azure-openai/gpt-5-4-mini}"
            ;;
        chat)
            chat_model "${1:-sandbox-gemini/gemini-2.5-flash}"
            ;;
        models)
            if [[ $# -lt 1 ]]; then
                log_error "Usage: bash scripts/quick-start-opencode.sh models <provider>"
                return 1
            fi
            start_session models "$1"
            ;;
        validate)
            validate_all
            ;;
        env)
            show_env
            ;;
        help)
            show_help
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            echo ""
            show_help
            return 1
            ;;
    esac
}

main "$@"
