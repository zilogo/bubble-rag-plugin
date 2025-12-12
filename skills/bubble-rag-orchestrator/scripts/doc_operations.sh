#!/bin/bash
# doc_operations.sh - Document operations for Bubble RAG

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/rag_utils.sh"
source "${SCRIPT_DIR}/api_client.sh"

# ============================================================================
# Upload Document
# ============================================================================

doc_upload() {
    local file_path="$1"
    local kb_id="${2:-}"
    local chunk_size="${3:-1000}"
    local data_clean="${4:-1}"
    local semantic_split="${5:-1}"
    local small2big="${6:-1}"
    local graphing="${7:-0}"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    # Get default KB if not specified
    if [[ -z "$kb_id" ]]; then
        kb_id=$(config_get 'RAG_DEFAULT_KB' '')
    fi

    if [[ -z "$kb_id" ]]; then
        error_msg "No knowledge base specified. Use --kb <id> or set default with '/rag-kb use <id>'"
        return 1
    fi

    validate_kb_id "$kb_id" || return 1

    # Check file exists
    if [[ ! -f "$file_path" ]]; then
        error_msg "File not found: $file_path"
        return 1
    fi

    # Check file is readable
    if [[ ! -r "$file_path" ]]; then
        error_msg "Cannot read file: $file_path"
        return 1
    fi

    local filename
    filename=$(basename "$file_path")
    local filesize
    filesize=$(wc -c < "$file_path" | tr -d ' ')

    echo ""
    progress_msg "Uploading document: $filename"
    echo "  File size: $filesize bytes"
    echo "  Target KB: $kb_id"
    echo ""

    local response
    response=$(api_upload "/documents/add_doc_task" "$file_path" \
        "doc_knowledge_base_id=$kb_id" \
        "chunk_size=$chunk_size" \
        "data_clean=$data_clean" \
        "semantic_split=$semantic_split" \
        "small2big=$small2big" \
        "graphing=$graphing")

    local data
    data=$(parse_response "$response") || return 1

    local task_id
    task_id=$(echo "$data" | jq -r '.[0].id // empty')

    if [[ -n "$task_id" ]]; then
        echo ""
        success_msg "Document uploaded successfully!"
        echo ""
        echo "  Task ID:  $task_id"
        echo "  Filename: $filename"
        echo ""
        echo "The document is now being processed. Check status with:"
        echo "  /rag-doc status $task_id"
        echo ""
        echo "Or wait for completion with:"
        echo "  /rag-doc wait $task_id"
        echo ""

        # Return task ID for scripting
        echo "$task_id"
    else
        error_msg "Failed to get task ID from response"
        return 1
    fi
}

# ============================================================================
# List Document Tasks
# ============================================================================

doc_list_tasks() {
    local kb_id="${1:-}"
    local page_num="${2:-1}"
    local page_size="${3:-20}"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    # Get default KB if not specified
    if [[ -z "$kb_id" ]]; then
        kb_id=$(config_get 'RAG_DEFAULT_KB' '')
    fi

    if [[ -z "$kb_id" ]]; then
        error_msg "No knowledge base specified. Use --kb <id> or set default with '/rag-kb use <id>'"
        return 1
    fi

    validate_kb_id "$kb_id" || return 1

    local payload
    payload=$(jq -n \
        --arg kb "$kb_id" \
        --argjson page "$page_num" \
        --argjson size "$page_size" \
        '{doc_knowledge_base_id: $kb, page_num: $page, page_size: $size}')

    progress_msg "Fetching document tasks..."

    local response
    response=$(api_request "POST" "/documents/list_doc_tasks" "$payload")

    local data
    data=$(parse_response "$response") || return 1

    echo ""
    echo -e "${BOLD}Document Tasks${NC}"
    echo "=============="
    echo ""
    echo "Knowledge Base: $kb_id"
    echo ""

    local total
    total=$(echo "$data" | jq -r '.total // 0')

    if [[ "$total" == "0" ]]; then
        echo "No document tasks found."
        echo ""
        echo "Upload documents with: /rag-doc upload <file>"
        return 0
    fi

    printf "%-20s %-30s %-12s %-10s %s\n" "Task ID" "Filename" "Status" "Progress" "Created"
    printf "%s\n" "$(printf '=%.0s' {1..100})"

    echo "$data" | jq -r '.items[] | [
        .id,
        (.curr_filename // "Processing..."),
        (if .split_status == 1 then "Complete" elif .split_status == -1 then "Processing" else "Pending" end),
        "\(.curr_file_progress)%",
        .create_time
    ] | @tsv' | \
    while IFS=$'\t' read -r id name status progress created; do
        local status_color=""
        case "$status" in
            Complete)
                status_color="${GREEN}${status}${NC}"
                ;;
            Processing)
                status_color="${YELLOW}${status}${NC}"
                ;;
            *)
                status_color="${BLUE}${status}${NC}"
                ;;
        esac

        printf "%-20s %-30s %-12b %-10s %s\n" \
            "${id:0:18}" \
            "${name:0:28}" \
            "$status_color" \
            "$progress" \
            "${created:0:19}"
    done

    echo ""
    echo "Total: $total task(s)"
    echo ""
}

# ============================================================================
# Get Task Status
# ============================================================================

doc_task_status() {
    local task_id="$1"
    local kb_id="${2:-}"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    if [[ -z "$task_id" ]]; then
        error_msg "Task ID is required"
        return 1
    fi

    # Get default KB if not specified
    if [[ -z "$kb_id" ]]; then
        kb_id=$(config_get 'RAG_DEFAULT_KB' '')
    fi

    if [[ -z "$kb_id" ]]; then
        error_msg "No knowledge base specified. Use --kb <id>"
        return 1
    fi

    local payload
    payload=$(jq -n \
        --arg kb "$kb_id" \
        '{doc_knowledge_base_id: $kb, page_num: 1, page_size: 100}')

    local response
    response=$(api_request "POST" "/documents/list_doc_tasks" "$payload")

    local data
    data=$(parse_response "$response") || return 1

    # Find the specific task
    local task_data
    task_data=$(echo "$data" | jq -r --arg id "$task_id" '.items[] | select(.id == $id)')

    if [[ -z "$task_data" ]]; then
        error_msg "Task not found: $task_id"
        return 1
    fi

    local status
    local progress
    local filename
    local content_length

    status=$(echo "$task_data" | jq -r 'if .split_status == 1 then "Complete" elif .split_status == -1 then "Processing" else "Pending" end')
    progress=$(echo "$task_data" | jq -r '.curr_file_progress // 0')
    filename=$(echo "$task_data" | jq -r '.curr_filename // "Unknown"')
    content_length=$(echo "$task_data" | jq -r '.content_length // 0')

    echo ""
    echo -e "${BOLD}Task Status${NC}"
    echo "==========="
    echo ""
    echo "  Task ID:        $task_id"
    echo "  Filename:       $filename"

    case "$status" in
        Complete)
            echo -e "  Status:         ${GREEN}$status${NC}"
            ;;
        Processing)
            echo -e "  Status:         ${YELLOW}$status${NC}"
            ;;
        *)
            echo -e "  Status:         ${BLUE}$status${NC}"
            ;;
    esac

    echo "  Progress:       ${progress}%"
    echo "  Content Length: $content_length characters"
    echo ""

    # Return status for scripting
    if [[ "$status" == "Complete" ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================================================
# Wait for Task Completion
# ============================================================================

doc_wait_completion() {
    local task_id="$1"
    local timeout="${2:-300}"
    local interval="${3:-5}"
    local kb_id="${4:-}"

    if [[ -z "$task_id" ]]; then
        error_msg "Task ID is required"
        return 1
    fi

    # Get default KB if not specified
    if [[ -z "$kb_id" ]]; then
        kb_id=$(config_get 'RAG_DEFAULT_KB' '')
    fi

    local start_time
    start_time=$(date +%s)

    echo ""
    progress_msg "Waiting for document processing to complete..."
    echo "  Task ID: $task_id"
    echo "  Timeout: ${timeout}s"
    echo ""

    while true; do
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))

        if [[ $elapsed -ge $timeout ]]; then
            error_msg "Timeout waiting for document processing (${timeout}s)"
            return 1
        fi

        # Check status silently
        if doc_task_status "$task_id" "$kb_id" >/dev/null 2>&1; then
            echo ""
            success_msg "Document processing complete!"
            echo ""
            echo "You can now query this document with '/rag'"
            echo ""
            return 0
        fi

        # Show progress
        local payload
        payload=$(jq -n --arg kb "$kb_id" '{doc_knowledge_base_id: $kb, page_num: 1, page_size: 100}')
        local response
        response=$(api_request "POST" "/documents/list_doc_tasks" "$payload" 2>/dev/null) || true

        local progress
        progress=$(echo "$response" | jq -r --arg id "$task_id" '.data.items[] | select(.id == $id) | .curr_file_progress // 0' 2>/dev/null) || progress="?"

        printf "\r  Progress: %s%% (elapsed: %ds)    " "$progress" "$elapsed"

        sleep "$interval"
    done
}

# ============================================================================
# Delete Document Task
# ============================================================================

doc_delete() {
    local task_id="$1"
    local kb_id="${2:-}"

    if ! check_auth; then
        error_msg "Not authenticated. Run '/rag-config login' first."
        return 1
    fi

    if [[ -z "$task_id" ]]; then
        error_msg "Task ID is required"
        return 1
    fi

    # Get default KB if not specified
    if [[ -z "$kb_id" ]]; then
        kb_id=$(config_get 'RAG_DEFAULT_KB' '')
    fi

    if [[ -z "$kb_id" ]]; then
        error_msg "No knowledge base specified. Use --kb <id>"
        return 1
    fi

    local payload
    payload=$(jq -n \
        --arg task "$task_id" \
        --arg kb "$kb_id" \
        '{task_id: $task, doc_knowledge_base_id: $kb}')

    progress_msg "Deleting document task: $task_id"

    local response
    response=$(api_request "POST" "/documents/delete_doc_task" "$payload")

    parse_response "$response" >/dev/null || return 1

    echo ""
    success_msg "Document task deleted successfully"
    echo ""
}
