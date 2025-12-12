#!/bin/bash
# session-start.sh - Session initialization hook for Bubble RAG plugin

set -euo pipefail

# ============================================================================
# Environment Setup
# ============================================================================

setup_environment() {
    # Check if we can write to env file
    if [[ -z "${CLAUDE_ENV_FILE:-}" ]]; then
        return 0
    fi

    # Set plugin root for convenience
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        echo "export RAG_PLUGIN_ROOT=\"${CLAUDE_PLUGIN_ROOT}\"" >> "$CLAUDE_ENV_FILE"
    fi

    # Maintain working directory
    echo "export CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR=1" >> "$CLAUDE_ENV_FILE"

    # Check if user is configured
    local config_file="$HOME/.bubble-rag/config"
    if [[ -f "$config_file" ]]; then
        echo "export RAG_CONFIGURED=1" >> "$CLAUDE_ENV_FILE"
    fi
}

# ============================================================================
# Dependency Validation
# ============================================================================

validate_dependencies() {
    local missing=()

    for cmd in curl jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Warning: Missing dependencies: ${missing[*]}" >&2
        echo "Some Bubble RAG features may not work correctly." >&2
        echo "Install with: brew install ${missing[*]} (macOS) or apt install ${missing[*]} (Linux)" >&2
    fi
}

# ============================================================================
# Status Check
# ============================================================================

check_rag_status() {
    local config_file="$HOME/.bubble-rag/config"
    local status_msg=""

    if [[ -f "$config_file" ]]; then
        # Check if token exists
        if grep -q "RAG_TOKEN=" "$config_file" 2>/dev/null; then
            status_msg="Bubble RAG Plugin: Authenticated"

            # Check for default KB
            local default_kb
            default_kb=$(grep "RAG_DEFAULT_KB=" "$config_file" 2>/dev/null | cut -d'"' -f2 || echo "")
            if [[ -n "$default_kb" ]]; then
                status_msg="$status_msg (Default KB: $default_kb)"
            fi
        else
            status_msg="Bubble RAG Plugin: Not authenticated. Run /rag-config login"
        fi
    else
        status_msg="Bubble RAG Plugin: Not configured. Run /rag-config login to get started"
    fi

    echo "$status_msg"
}

# ============================================================================
# Main
# ============================================================================

main() {
    # Validate dependencies (warnings only)
    validate_dependencies 2>/dev/null || true

    # Setup environment
    setup_environment 2>/dev/null || true

    # Get status message
    local status
    status=$(check_rag_status)

    # Output JSON response for Claude Code
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "$status. Use /rag-help for available commands."
  }
}
EOF
}

main
