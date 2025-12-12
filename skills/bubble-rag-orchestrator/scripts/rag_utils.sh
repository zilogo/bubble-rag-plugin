#!/bin/bash
# rag_utils.sh - Core utility functions for Bubble RAG plugin

set -euo pipefail

# Configuration
RAG_CONFIG_DIR="${RAG_CONFIG_DIR:-$HOME/.bubble-rag}"
RAG_CONFIG_FILE="${RAG_CONFIG_DIR}/config"
RAG_DEFAULT_SERVER="http://localhost:8000"
RAG_API_PREFIX="/bubble_rag/api/v1"

# Default model IDs
DEFAULT_RERANK_MODEL="154605956896915473"
DEFAULT_EMBEDDING_MODEL="154605669335433233"

# Colors (only if terminal supports it)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# ============================================================================
# Message Helpers
# ============================================================================

progress_msg() { echo -e "${YELLOW}>>> $1${NC}" >&2; }
error_msg() { echo -e "${RED}ERROR: $1${NC}" >&2; }
success_msg() { echo -e "${GREEN}✓ $1${NC}" >&2; }
info_msg() { echo -e "${BLUE}$1${NC}" >&2; }
warn_msg() { echo -e "${YELLOW}WARNING: $1${NC}" >&2; }

# ============================================================================
# Configuration Management
# ============================================================================

# Initialize config directory
init_config() {
    if [[ ! -d "$RAG_CONFIG_DIR" ]]; then
        mkdir -p "$RAG_CONFIG_DIR"
        chmod 700 "$RAG_CONFIG_DIR"
    fi
    if [[ ! -f "$RAG_CONFIG_FILE" ]]; then
        touch "$RAG_CONFIG_FILE"
        chmod 600 "$RAG_CONFIG_FILE"
    fi
}

# Load configuration
load_config() {
    init_config
    if [[ -f "$RAG_CONFIG_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$RAG_CONFIG_FILE"
    fi
}

# Get config value
config_get() {
    local key="$1"
    local default="${2:-}"
    load_config
    local value="${!key:-$default}"
    echo "$value"
}

# Set config value
config_set() {
    local key="$1"
    local value="$2"
    init_config

    # Remove existing key
    if [[ -f "$RAG_CONFIG_FILE" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/^${key}=/d" "$RAG_CONFIG_FILE" 2>/dev/null || true
        else
            sed -i "/^${key}=/d" "$RAG_CONFIG_FILE" 2>/dev/null || true
        fi
    fi

    # Append new value
    echo "${key}=\"${value}\"" >> "$RAG_CONFIG_FILE"
    chmod 600 "$RAG_CONFIG_FILE"
}

# Delete config value
config_delete() {
    local key="$1"
    init_config

    if [[ -f "$RAG_CONFIG_FILE" ]]; then
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "/^${key}=/d" "$RAG_CONFIG_FILE" 2>/dev/null || true
        else
            sed -i "/^${key}=/d" "$RAG_CONFIG_FILE" 2>/dev/null || true
        fi
    fi
}

# List all config
config_list() {
    echo ""
    echo -e "${BOLD}Bubble RAG Configuration${NC}"
    echo "========================="
    echo ""
    echo "Config file: $RAG_CONFIG_FILE"
    echo ""

    if [[ -f "$RAG_CONFIG_FILE" ]] && [[ -s "$RAG_CONFIG_FILE" ]]; then
        while IFS='=' read -r key value; do
            [[ -z "$key" || "$key" =~ ^# ]] && continue
            # Mask token
            if [[ "$key" == "RAG_TOKEN" ]]; then
                local masked_value="${value:0:20}...***"
                echo "  $key: $masked_value"
            else
                echo "  $key: $value"
            fi
        done < "$RAG_CONFIG_FILE"
    else
        echo "  (no configuration set)"
    fi
    echo ""
}

# Reset config to defaults
config_reset() {
    if [[ -f "$RAG_CONFIG_FILE" ]]; then
        rm -f "$RAG_CONFIG_FILE"
        init_config
        success_msg "Configuration reset to defaults"
    fi
}

# ============================================================================
# Authentication Helpers
# ============================================================================

# Check if authenticated
check_auth() {
    local token
    token=$(config_get "RAG_TOKEN" "")
    [[ -n "$token" ]]
}

# Get current server URL
get_server_url() {
    config_get "RAG_SERVER_URL" "$RAG_DEFAULT_SERVER"
}

# Get API base URL
get_api_base() {
    local server
    server=$(get_server_url)
    echo "${server}${RAG_API_PREFIX}"
}

# ============================================================================
# Validation Helpers
# ============================================================================

# Input validation
validate_input() {
    local input="$1"
    local max_length="${2:-10000}"

    if [[ ${#input} -gt $max_length ]]; then
        error_msg "Input exceeds maximum length ($max_length characters)"
        return 1
    fi

    # Check for null bytes (shell injection vector)
    if [[ "$input" == *$'\0'* ]]; then
        error_msg "Input contains invalid characters"
        return 1
    fi

    return 0
}

# Validate knowledge base ID format
validate_kb_id() {
    local kb_id="$1"

    if [[ -z "$kb_id" ]]; then
        error_msg "Knowledge base ID is required"
        return 1
    fi

    # KB IDs should be numeric strings
    if ! [[ "$kb_id" =~ ^[0-9]+$ ]]; then
        error_msg "Invalid knowledge base ID format: $kb_id"
        return 1
    fi

    return 0
}

# ============================================================================
# Prerequisites Check
# ============================================================================

check_prerequisites() {
    local missing=()

    for cmd in curl jq; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        error_msg "Missing dependencies: ${missing[*]}"
        echo ""
        echo "Please install the missing dependencies:"
        for cmd in "${missing[@]}"; do
            case "$cmd" in
                curl)
                    echo "  - curl: brew install curl (macOS) or apt install curl (Linux)"
                    ;;
                jq)
                    echo "  - jq: brew install jq (macOS) or apt install jq (Linux)"
                    ;;
            esac
        done
        return 1
    fi

    return 0
}

# ============================================================================
# Status Check
# ============================================================================

check_status() {
    load_config
    local server
    server=$(get_server_url)

    echo ""
    echo -e "${BOLD}Bubble RAG Status${NC}"
    echo "================="
    echo ""
    echo "Server URL:     $server"

    # Check connectivity
    if curl -s --connect-timeout 5 "${server}/health" &>/dev/null; then
        echo -e "Server Status:  ${GREEN}Connected${NC}"
    else
        echo -e "Server Status:  ${RED}Disconnected${NC}"
    fi

    # Check auth
    if check_auth; then
        local username
        username=$(config_get "RAG_USERNAME" "unknown")
        echo -e "Authentication: ${GREEN}Authenticated${NC}"
        echo "Username:       $username"
    else
        echo -e "Authentication: ${YELLOW}Not authenticated${NC}"
        echo ""
        echo "Run '/rag-config login' to authenticate"
    fi

    local default_kb
    default_kb=$(config_get "RAG_DEFAULT_KB" "")
    if [[ -n "$default_kb" ]]; then
        echo "Default KB:     $default_kb"
    else
        echo "Default KB:     (not set)"
    fi

    echo ""
    echo "Config File:    $RAG_CONFIG_FILE"
    echo ""
}

# ============================================================================
# Plugin Root Resolution
# ============================================================================

get_plugin_root() {
    # Check environment variables in order of preference
    if [[ -n "${RAG_PLUGIN_ROOT:-}" ]]; then
        echo "$RAG_PLUGIN_ROOT"
        return 0
    fi

    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        echo "$CLAUDE_PLUGIN_ROOT"
        return 0
    fi

    if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
        echo "$CLAUDE_PROJECT_DIR"
        return 0
    fi

    # Try to find based on script location
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # Navigate up from scripts/ to plugin root
    local plugin_root="${script_dir}/../../.."
    if [[ -f "${plugin_root}/.claude-plugin/plugin.json" ]]; then
        echo "$(cd "$plugin_root" && pwd)"
        return 0
    fi

    # Fallback: standard installation locations
    for candidate in \
        "$HOME/.claude/plugins/cache/bubble-rag/bubble-rag-plugin/1.0.0" \
        "$HOME/.claude/plugins/bubble-rag-plugin"; do
        if [[ -d "$candidate" ]]; then
            echo "$candidate"
            return 0
        fi
    done

    error_msg "Cannot locate plugin root directory"
    return 1
}

# ============================================================================
# JSON Helpers
# ============================================================================

# Safe JSON string escaping
json_escape() {
    local str="$1"
    printf '%s' "$str" | jq -Rs .
}

# Extract value from JSON response
json_get() {
    local json="$1"
    local path="$2"
    local default="${3:-}"

    local value
    value=$(echo "$json" | jq -r "$path // empty" 2>/dev/null)

    if [[ -z "$value" || "$value" == "null" ]]; then
        echo "$default"
    else
        echo "$value"
    fi
}
