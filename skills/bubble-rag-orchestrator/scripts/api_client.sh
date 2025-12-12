#!/bin/bash
# api_client.sh - HTTP API client for Bubble RAG

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rag_utils.sh"

# ============================================================================
# Core API Request Functions
# ============================================================================

# Make authenticated API request
api_request() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    load_config
    local server
    server=$(get_server_url)
    local token
    token=$(config_get "RAG_TOKEN" "")
    local url="${server}${RAG_API_PREFIX}${endpoint}"
    local timeout
    timeout=$(config_get "RAG_TIMEOUT" "60")

    local curl_args=(
        -s
        -X "$method"
        -H "Content-Type: application/json"
        --connect-timeout 10
        --max-time "$timeout"
    )

    if [[ -n "$token" ]]; then
        curl_args+=(-H "Authorization: Bearer $token")
        curl_args+=(-H "x-token: $token")
    fi

    if [[ -n "$data" ]]; then
        curl_args+=(-d "$data")
    fi

    local response
    response=$(curl "${curl_args[@]}" "$url" 2>/dev/null) || {
        error_msg "Failed to connect to server: $url"
        return 1
    }

    echo "$response"
}

# Upload file (multipart/form-data)
api_upload() {
    local endpoint="$1"
    local file_path="$2"
    shift 2
    local form_fields=("$@")

    load_config
    local server
    server=$(get_server_url)
    local token
    token=$(config_get "RAG_TOKEN" "")
    local url="${server}${RAG_API_PREFIX}${endpoint}"

    local curl_args=(
        -s
        -X POST
        --connect-timeout 10
        --max-time 300
    )

    if [[ -n "$token" ]]; then
        curl_args+=(-H "Authorization: Bearer $token")
        curl_args+=(-H "x-token: $token")
    fi

    curl_args+=(-F "files=@${file_path}")

    for field in "${form_fields[@]}"; do
        curl_args+=(-F "$field")
    done

    local response
    response=$(curl "${curl_args[@]}" "$url" 2>/dev/null) || {
        error_msg "Failed to upload file to: $url"
        return 1
    }

    echo "$response"
}

# ============================================================================
# Response Parsing
# ============================================================================

# Parse API response and handle errors
parse_response() {
    local response="$1"
    local code
    local msg
    local data

    code=$(echo "$response" | jq -r '.code // 0')
    msg=$(echo "$response" | jq -r '.msg // "Unknown error"')

    if [[ "$code" == "200" ]]; then
        data=$(echo "$response" | jq -r '.data // empty')
        echo "$data"
        return 0
    else
        error_msg "API Error ($code): $msg"
        return 1
    fi
}

# Check if response indicates auth error
is_auth_error() {
    local response="$1"
    local code
    code=$(echo "$response" | jq -r '.code // 0')

    [[ "$code" == "401" || "$code" == "403" ]]
}

# ============================================================================
# RAG Chat/Query Function
# ============================================================================

# Chat/Q&A with RAG
rag_chat() {
    local question="$1"
    local kb_id="${2:-}"
    local limit_result="${3:-5}"
    local temperature="${4:-0.7}"

    # Get default KB if not specified
    if [[ -z "$kb_id" ]]; then
        kb_id=$(config_get 'RAG_DEFAULT_KB' '')
    fi

    if [[ -z "$kb_id" ]]; then
        error_msg "No knowledge base specified. Use --kb or set default with /rag-kb use <id>"
        return 1
    fi

    validate_input "$question" || return 1
    validate_kb_id "$kb_id" || return 1

    local payload
    payload=$(jq -n \
        --arg q "$question" \
        --arg kb "$kb_id" \
        --argjson limit "$limit_result" \
        --argjson temp "$temperature" \
        '{
            messages: [{role: "user", content: $q}],
            doc_knowledge_base_id: $kb,
            limit_result: $limit,
            graphing: false,
            stream: false,
            temperature: $temp,
            max_tokens: 2000
        }')

    progress_msg "Querying knowledge base..."

    local response
    response=$(api_request "POST" "/chat/completions" "$payload")

    # Check for auth error
    if is_auth_error "$response"; then
        error_msg "Authentication failed. Please run '/rag-config login' to re-authenticate."
        return 1
    fi

    # Extract answer from OpenAI-compatible response format
    local answer
    answer=$(echo "$response" | jq -r '.choices[0].message.content // empty')

    if [[ -n "$answer" ]]; then
        # Remove thinking tags if present
        answer=$(echo "$answer" | sed 's/<think>.*<\/think>//g' | sed '/^$/d')
        echo "$answer"
        return 0
    else
        local error
        error=$(echo "$response" | jq -r '.msg // .error.message // "Unknown error"')
        error_msg "Chat failed: $error"
        return 1
    fi
}

# ============================================================================
# Knowledge Base Selection Helper
# ============================================================================

# Get knowledge base or prompt for selection
get_or_select_kb() {
    local kb_id="${1:-}"

    # If KB ID provided, use it
    if [[ -n "$kb_id" ]]; then
        echo "$kb_id"
        return 0
    fi

    # Check for default KB
    kb_id=$(config_get 'RAG_DEFAULT_KB' '')
    if [[ -n "$kb_id" ]]; then
        echo "$kb_id"
        return 0
    fi

    # List available KBs
    local payload='{"kb_name": "", "page_num": 1, "page_size": 50}'
    local response
    response=$(api_request "POST" "/knowledge_base/list_knowledge_base" "$payload")

    local data
    data=$(parse_response "$response") || return 1

    local total
    total=$(echo "$data" | jq -r '.total // 0')

    if [[ "$total" == "0" ]]; then
        error_msg "No knowledge bases found. Create one with '/rag-kb create <name>'"
        return 1
    fi

    # If only one KB, use it automatically
    if [[ "$total" == "1" ]]; then
        kb_id=$(echo "$data" | jq -r '.items[0].id')
        local kb_name
        kb_name=$(echo "$data" | jq -r '.items[0].kb_name')
        info_msg "Using the only available knowledge base: $kb_name ($kb_id)"
        info_msg "Tip: Run '/rag-kb use $kb_id' to set it as default"
        echo "$kb_id"
        return 0
    fi

    # Multiple KBs - need user selection
    echo ""
    echo -e "${YELLOW}No default knowledge base set. Available knowledge bases:${NC}"
    echo ""

    local index=1
    echo "$data" | jq -r '.items[] | "\(.id)\t\(.kb_name)\t\(.kb_desc // "-")"' | \
    while IFS=$'\t' read -r id name desc; do
        printf "  [%d] %s - %s\n" "$index" "$name" "${desc:0:40}"
        ((index++))
    done

    echo ""
    echo "Please specify a knowledge base:"
    echo "  - Use '/rag \"question\" --kb <id>' for this query"
    echo "  - Use '/rag-kb use <id>' to set a default"
    echo ""

    # Return error to indicate selection needed
    return 2
}
