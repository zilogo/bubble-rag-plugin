---
name: bubble-rag-orchestrator
description: Orchestrates Bubble RAG API interactions for knowledge base management, document processing, and intelligent Q&A retrieval. Use when you need to query project documentation, upload files to knowledge base, or manage RAG configurations.
---

# Bubble RAG Orchestrator

## Overview

This skill provides seamless integration with Bubble RAG API for enterprise-grade retrieval-augmented generation capabilities.

**Core Features:**
- Knowledge base CRUD operations
- Document upload and processing
- Semantic search and Q&A
- Configuration management

## Quick Start

### Prerequisites Check

```bash
# Resolve path to scripts
if [[ -n "${RAG_PLUGIN_ROOT:-}" ]]; then
    SCRIPTS_PATH="${RAG_PLUGIN_ROOT}/skills/bubble-rag-orchestrator/scripts"
elif [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    SCRIPTS_PATH="${CLAUDE_PLUGIN_ROOT}/skills/bubble-rag-orchestrator/scripts"
else
    SCRIPTS_PATH="${CLAUDE_PROJECT_DIR}/skills/bubble-rag-orchestrator/scripts"
fi

source "${SCRIPTS_PATH}/rag_utils.sh"
check_prerequisites
```

### Authentication

```bash
source "${SCRIPTS_PATH}/auth.sh"
rag_login "username" "password" "http://server:8000"
```

## Execution Flow

### 1. Query Knowledge Base

```bash
source "${SCRIPTS_PATH}/api_client.sh"

# Simple query
answer=$(rag_chat "What is the main architecture?" "$kb_id")

# With options
answer=$(rag_chat "Explain authentication" "$kb_id" 10 0.7)
```

### 2. Manage Knowledge Bases

```bash
source "${SCRIPTS_PATH}/kb_operations.sh"

# List
kb_list

# Create
kb_id=$(kb_create "New KB" "Description")

# Set default
kb_use "$kb_id"

# Delete
kb_delete "$kb_id"
```

### 3. Upload Documents

```bash
source "${SCRIPTS_PATH}/doc_operations.sh"

# Upload file
task_id=$(doc_upload "/path/to/file.pdf" "$kb_id")

# Wait for processing
doc_wait_completion "$task_id" 300  # 5 min timeout
```

### 4. Check Status

```bash
source "${SCRIPTS_PATH}/rag_utils.sh"
check_status
```

## API Reference

### Authentication

| Function | Parameters | Description |
|----------|------------|-------------|
| `rag_login` | username, password, [server_url] | Login or register |
| `rag_logout` | - | Clear credentials |
| `check_auth` | - | Check if authenticated |

### Knowledge Base Operations

| Function | Parameters | Description |
|----------|------------|-------------|
| `kb_list` | [page_num], [page_size] | List knowledge bases |
| `kb_create` | name, [desc], [rerank_model], [embed_model] | Create KB |
| `kb_delete` | kb_id, [force] | Delete KB |
| `kb_info` | kb_id | Get KB details |
| `kb_use` | kb_id | Set default KB |

### Document Operations

| Function | Parameters | Description |
|----------|------------|-------------|
| `doc_upload` | file_path, [kb_id], [chunk_size], ... | Upload document |
| `doc_list_tasks` | [kb_id], [page_num], [page_size] | List tasks |
| `doc_task_status` | task_id, [kb_id] | Get task status |
| `doc_wait_completion` | task_id, [timeout], [interval], [kb_id] | Wait for completion |
| `doc_delete` | task_id, [kb_id] | Delete task |

### Query Operations

| Function | Parameters | Description |
|----------|------------|-------------|
| `rag_chat` | question, [kb_id], [limit], [temperature] | Q&A query |
| `get_or_select_kb` | [kb_id] | Smart KB selection |

### Configuration

| Function | Parameters | Description |
|----------|------------|-------------|
| `config_get` | key, [default] | Get config value |
| `config_set` | key, value | Set config value |
| `config_list` | - | List all config |
| `config_reset` | - | Reset to defaults |

## Error Handling

| Error | Handling |
|-------|----------|
| 401 Unauthorized | Re-authenticate with `/rag-config login` |
| 404 Not Found | Verify KB/Document ID exists |
| 410 Business Error | Check msg field for details |
| 500 Server Error | Contact administrator |

## Security Best Practices

### Credential Storage

- Credentials stored in `~/.bubble-rag/config`
- File permissions set to 600 (owner read/write only)
- Directory permissions set to 700

### Input Validation

```bash
source "${SCRIPTS_PATH}/rag_utils.sh"

# Validate user input
validate_input "$user_query" 10000 || exit 1

# Validate KB ID
validate_kb_id "$kb_id" || exit 1
```

### Token Handling

- Token transmitted via Authorization header
- Token masked in config display
- No token logging in debug output

## Output Format

### Query Response

The RAG query returns AI-generated answers based on:
- Semantic search results from vector database
- Context from matching document chunks
- LLM synthesis of retrieved information

### Task Status Values

| split_status | Meaning |
|--------------|---------|
| -1 | Processing |
| 0 | Pending |
| 1 | Complete |

## Configuration Variables

| Variable | Default | Description |
|----------|---------|-------------|
| RAG_SERVER_URL | http://localhost:8000 | API server URL |
| RAG_DEFAULT_KB | (none) | Default knowledge base ID |
| RAG_CHUNK_SIZE | 1000 | Document chunk size |
| RAG_LIMIT_RESULT | 5 | Number of retrieval results |
| RAG_TIMEOUT | 60 | API timeout seconds |

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `rag_utils.sh` | Core utilities, config management |
| `api_client.sh` | HTTP API wrapper, RAG chat |
| `auth.sh` | Authentication functions |
| `kb_operations.sh` | Knowledge base CRUD |
| `doc_operations.sh` | Document upload/management |

## Common Usage Patterns

### Full Workflow Example

```bash
# Setup
source "${SCRIPTS_PATH}/rag_utils.sh"
source "${SCRIPTS_PATH}/auth.sh"
source "${SCRIPTS_PATH}/kb_operations.sh"
source "${SCRIPTS_PATH}/doc_operations.sh"
source "${SCRIPTS_PATH}/api_client.sh"

# 1. Login
rag_login "user" "password" "http://server:8000"

# 2. Create knowledge base
kb_id=$(kb_create "My Project Docs" "Documentation for my project")

# 3. Set as default
kb_use "$kb_id"

# 4. Upload documents
task_id=$(doc_upload "/docs/readme.md" "$kb_id")

# 5. Wait for processing
doc_wait_completion "$task_id"

# 6. Query
answer=$(rag_chat "What is this project about?")
echo "$answer"
```

### Check and Query

```bash
source "${SCRIPTS_PATH}/rag_utils.sh"
source "${SCRIPTS_PATH}/api_client.sh"

# Check auth
if ! check_auth; then
    echo "Please login first"
    exit 1
fi

# Query with smart KB selection
kb_id=$(get_or_select_kb "")
if [[ -n "$kb_id" ]]; then
    rag_chat "Your question here" "$kb_id"
fi
```
