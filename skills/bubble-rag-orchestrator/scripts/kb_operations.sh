#!/bin/bash
# kb_operations.sh - Knowledge base operations for Bubble RAG

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rag_utils.sh"
source "${SCRIPT_DIR}/api_client.sh"

# ============================================================================
# List Knowledge Bases
# ============================================================================

kb_list() {
    local page_num="${1:-1}"
    local page_size="${2:-20}"
    local kb_name="${3:-}"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    local payload
    payload=$(jq -n \
        --arg name "$kb_name" \
        --argjson page "$page_num" \
        --argjson size "$page_size" \
        '{kb_name: $name, page_num: $page, page_size: $size}')

    progress_msg "Fetching knowledge bases..."

    local response
    response=$(api_request "POST" "/knowledge_base/list_knowledge_base" "$payload")

    local data
    data=$(parse_response "$response") || return 1

    # Format output
    echo ""
    echo -e "${BOLD}Knowledge Bases${NC}"
    echo "==============="
    echo ""

    local total
    total=$(echo "$data" | jq -r '.total // 0')

    if [[ "$total" == "0" ]]; then
        echo "No knowledge bases found."
        echo ""
        echo "Create one with: /rag-kb create \"My Knowledge Base\""
        return 0
    fi

    # Get default KB for highlighting
    local default_kb
    default_kb=$(config_get "RAG_DEFAULT_KB" "")

    printf "%-20s %-30s %-35s %s\n" "ID" "Name" "Description" "Created"
    printf "%s\n" "$(printf '=%.0s' {1..110})"

    echo "$data" | jq -r '.items[] | [.id, .kb_name, (.kb_desc // "-"), .create_time] | @tsv' | \
    while IFS=$'\t' read -r id name desc created; do
        local marker=""
        if [[ "$id" == "$default_kb" ]]; then
            marker=" ${GREEN}*${NC}"
        fi
        printf "%-20s %-30s %-35s %s%b\n" \
            "${id:0:18}" \
            "${name:0:28}" \
            "${desc:0:33}" \
            "${created:0:19}" \
            "$marker"
    done

    echo ""
    echo "Total: $total knowledge base(s)"

    if [[ -n "$default_kb" ]]; then
        echo -e "${GREEN}*${NC} = default knowledge base"
    fi
    echo ""
}

# ============================================================================
# Create Knowledge Base
# ============================================================================

kb_create() {
    local name="$1"
    local desc="${2:-}"
    local rerank_model="${3:-$DEFAULT_RERANK_MODEL}"
    local embedding_model="${4:-$DEFAULT_EMBEDDING_MODEL}"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    validate_input "$name" 100 || return 1

    local payload
    payload=$(jq -n \
        --arg name "$name" \
        --arg desc "$desc" \
        --arg rerank "$rerank_model" \
        --arg embed "$embedding_model" \
        '{
            kb_name: $name,
            kb_desc: $desc,
            rerank_model_id: $rerank,
            embedding_model_id: $embed
        }')

    progress_msg "Creating knowledge base: $name"

    local response
    response=$(api_request "POST" "/knowledge_base/add_knowledge_base" "$payload")

    local data
    data=$(parse_response "$response") || return 1

    local kb_id
    kb_id=$(echo "$data" | jq -r '.id')

    echo ""
    success_msg "Knowledge base created successfully!"
    echo ""
    echo "  ID:          $kb_id"
    echo "  Name:        $name"
    if [[ -n "$desc" ]]; then
        echo "  Description: $desc"
    fi
    echo ""
    echo "Next steps:"
    echo "  - Upload documents: /rag-doc upload <file> --kb $kb_id"
    echo "  - Set as default:   /rag-kb use $kb_id"
    echo ""

    # Return just the ID for scripting
    echo "$kb_id"
}

# ============================================================================
# Delete Knowledge Base
# ============================================================================

kb_delete() {
    local kb_id="$1"
    local force="${2:-false}"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    validate_kb_id "$kb_id" || return 1

    # Confirmation warning
    if [[ "$force" != "true" ]]; then
        echo ""
        echo -e "${RED}WARNING: This action is irreversible!${NC}"
        echo ""
        echo "Deleting knowledge base $kb_id will remove:"
        echo "  - The knowledge base itself"
        echo "  - All documents in the knowledge base"
        echo "  - All vector embeddings and metadata"
        echo ""
    fi

    local payload
    payload=$(jq -n --arg id "$kb_id" '{kb_id: $id}')

    progress_msg "Deleting knowledge base: $kb_id"

    local response
    response=$(api_request "POST" "/knowledge_base/delete_knowledge_base" "$payload")

    parse_response "$response" >/dev/null || return 1

    # Clear default KB if it was deleted
    local default_kb
    default_kb=$(config_get "RAG_DEFAULT_KB" "")
    if [[ "$default_kb" == "$kb_id" ]]; then
        config_delete "RAG_DEFAULT_KB"
        info_msg "Cleared default knowledge base setting"
    fi

    echo ""
    success_msg "Knowledge base deleted successfully"
    echo ""
}

# ============================================================================
# Get Knowledge Base Details
# ============================================================================

kb_info() {
    local kb_id="$1"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    validate_kb_id "$kb_id" || return 1

    # Use list API with filter to get details
    local payload
    payload=$(jq -n '{kb_name: "", page_num: 1, page_size: 100}')

    progress_msg "Fetching knowledge base details..."

    local response
    response=$(api_request "POST" "/knowledge_base/list_knowledge_base" "$payload")

    local data
    data=$(parse_response "$response") || return 1

    # Find the specific KB
    local kb_data
    kb_data=$(echo "$data" | jq -r --arg id "$kb_id" '.items[] | select(.id == $id)')

    if [[ -z "$kb_data" ]]; then
        error_msg "Knowledge base not found: $kb_id"
        return 1
    fi

    echo ""
    echo -e "${BOLD}Knowledge Base Details${NC}"
    echo "======================"
    echo ""

    echo "$kb_data" | jq -r '
        "  ID:              \(.id)",
        "  Name:            \(.kb_name)",
        "  Description:     \(.kb_desc // "-")",
        "  Collection:      \(.coll_name // "-")",
        "  Rerank Model:    \(.rerank_model_id // "-")",
        "  Embedding Model: \(.embedding_model_id // "-")",
        "  Created:         \(.create_time)",
        "  Updated:         \(.update_time)"
    '

    # Check if this is the default KB
    local default_kb
    default_kb=$(config_get "RAG_DEFAULT_KB" "")
    if [[ "$default_kb" == "$kb_id" ]]; then
        echo -e "  Default:         ${GREEN}Yes${NC}"
    fi

    echo ""
}

# ============================================================================
# Set Default Knowledge Base
# ============================================================================

kb_use() {
    local kb_id="$1"

    validate_kb_id "$kb_id" || return 1

    # Verify KB exists
    if check_auth; then
        local payload
        payload=$(jq -n '{kb_name: "", page_num: 1, page_size: 100}')

        local response
        response=$(api_request "POST" "/knowledge_base/list_knowledge_base" "$payload")

        local data
        data=$(parse_response "$response" 2>/dev/null) || true

        if [[ -n "$data" ]]; then
            local exists
            exists=$(echo "$data" | jq -r --arg id "$kb_id" '.items[] | select(.id == $id) | .id')

            if [[ -z "$exists" ]]; then
                warn_msg "Knowledge base $kb_id not found. Setting as default anyway."
            fi
        fi
    fi

    config_set "RAG_DEFAULT_KB" "$kb_id"

    echo ""
    success_msg "Default knowledge base set to: $kb_id"
    echo ""
    echo "All '/rag' queries will now use this knowledge base by default."
    echo "Override with '/rag \"question\" --kb <other_id>' when needed."
    echo ""
}

# ============================================================================
# Clear Default Knowledge Base
# ============================================================================

kb_clear_default() {
    config_delete "RAG_DEFAULT_KB"

    echo ""
    success_msg "Default knowledge base cleared"
    echo ""
    echo "You will now be prompted to select a knowledge base when querying."
    echo ""
}
