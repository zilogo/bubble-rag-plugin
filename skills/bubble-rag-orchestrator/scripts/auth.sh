#!/bin/bash
# auth.sh - Authentication functions for Bubble RAG

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rag_utils.sh"
source "${SCRIPT_DIR}/api_client.sh"

# ============================================================================
# Login / Register
# ============================================================================

# Login or create user
rag_login() {
    local username="$1"
    local password="${2:-laiye123}"
    local server_url="${3:-}"

    # Use provided server or get from config/default
    if [[ -z "$server_url" ]]; then
        server_url=$(get_server_url)
    fi

    validate_input "$username" 50 || return 1
    validate_input "$password" 128 || return 1

    # Save server URL first
    config_set "RAG_SERVER_URL" "$server_url"

    progress_msg "Authenticating with $server_url..."

    local payload
    payload=$(jq -n \
        --arg u "$username" \
        --arg p "$password" \
        '{username: $u, user_password: $p}')

    local response
    response=$(api_request "POST" "/auth/login_or_create" "$payload") || {
        error_msg "Failed to connect to server"
        return 1
    }

    local code
    code=$(echo "$response" | jq -r '.code // 0')

    if [[ "$code" == "200" ]]; then
        local token
        local user_role
        local display_name

        token=$(echo "$response" | jq -r '.data.token')
        user_role=$(echo "$response" | jq -r '.data.user_role // "user"')
        display_name=$(echo "$response" | jq -r '.data.display_name // .data.username')

        config_set "RAG_TOKEN" "$token"
        config_set "RAG_USERNAME" "$username"
        config_set "RAG_USER_ROLE" "$user_role"

        echo ""
        success_msg "Login successful!"
        echo ""
        echo "  Username:    $display_name"
        echo "  Role:        $user_role"
        echo "  Server:      $server_url"
        echo ""
        echo "You can now use '/rag' to query your knowledge bases."
        echo "Run '/rag-kb list' to see available knowledge bases."
        echo ""

        return 0
    else
        local msg
        msg=$(echo "$response" | jq -r '.msg // "Authentication failed"')
        error_msg "$msg"
        return 1
    fi
}

# ============================================================================
# Logout
# ============================================================================

# Logout (clear credentials)
rag_logout() {
    init_config

    # Clear sensitive data
    config_delete "RAG_TOKEN"
    config_delete "RAG_USERNAME"
    config_delete "RAG_USER_ROLE"

    echo ""
    success_msg "Logged out successfully"
    echo ""
    echo "Your server URL and other settings have been preserved."
    echo "Run '/rag-config login' to authenticate again."
    echo ""
}

# ============================================================================
# Authentication Verification
# ============================================================================

# Verify current authentication is valid
rag_verify_auth() {
    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    progress_msg "Verifying authentication..."

    # Try to list knowledge bases as a verification
    local payload='{"kb_name": "", "page_num": 1, "page_size": 1}'
    local response
    response=$(api_request "POST" "/knowledge_base/list_knowledge_base" "$payload")

    local code
    code=$(echo "$response" | jq -r '.code // 0')

    if [[ "$code" == "200" ]]; then
        local username
        username=$(config_get "RAG_USERNAME" "unknown")
        echo ""
        success_msg "Authentication valid"
        echo ""
        echo "  Username: $username"
        echo "  Server:   $(get_server_url)"
        echo ""
        return 0
    elif [[ "$code" == "401" || "$code" == "403" ]]; then
        error_msg "Token expired or invalid. Please login again with '/rag-config login'"
        return 1
    else
        local msg
        msg=$(echo "$response" | jq -r '.msg // "Verification failed"')
        error_msg "$msg"
        return 1
    fi
}

# ============================================================================
# Interactive Login
# ============================================================================

# Interactive login prompt (for use in commands)
rag_interactive_login() {
    local server_url="${1:-}"

    echo ""
    echo -e "${BOLD}Bubble RAG Login${NC}"
    echo "================"
    echo ""

    # Server URL
    if [[ -z "$server_url" ]]; then
        local default_server
        default_server=$(get_server_url)
        echo "Server URL (default: $default_server):"
        read -r server_url
        if [[ -z "$server_url" ]]; then
            server_url="$default_server"
        fi
    fi

    echo ""
    echo "Server: $server_url"
    echo ""

    # Username
    echo "Username:"
    read -r username

    if [[ -z "$username" ]]; then
        error_msg "Username is required"
        return 1
    fi

    # Password
    echo "Password (default: laiye123):"
    read -rs password
    echo ""

    if [[ -z "$password" ]]; then
        password="laiye123"
    fi

    # Perform login
    rag_login "$username" "$password" "$server_url"
}
