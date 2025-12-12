---
description: Upload and manage documents in your Bubble RAG knowledge base.
argument-hint: "<action> [args]"
model: claude-haiku-4-5-20251001
---

# Document Management

Upload documents and manage document processing tasks.

## Usage

```
/rag-doc upload <file_path> [--kb <kb_id>]  # Upload a document
/rag-doc list [--kb <kb_id>]                # List document tasks
/rag-doc status <task_id> [--kb <kb_id>]    # Check task status
/rag-doc wait <task_id> [--kb <kb_id>]      # Wait for task completion
/rag-doc delete <task_id> [--kb <kb_id>]    # Delete a document task
```

## Supported File Formats

- Text files: `.txt`
- Office documents: `.docx`, `.doc`
- PDF documents: `.pdf`

## Examples

```
/rag-doc upload /path/to/document.pdf
/rag-doc upload README.md --kb 155878243264626698
/rag-doc list
/rag-doc list --kb 155878243264626698
/rag-doc status 155878462324736010
/rag-doc wait 155878462324736010
/rag-doc delete 155878462324736010
```

## Output Format

### List Output
```
Document Tasks
==============

Knowledge Base: 155878243264626698

Task ID              Filename                       Status       Progress   Created
====================================================================================================
155878462324736010   document.pdf                   Complete     100%       2025-12-11T16:33:24
155993312635912201   readme.txt                     Processing   50%        2025-12-12T11:34:20

Total: 2 task(s)
```

### Status Output
```
Task Status
===========

  Task ID:        155878462324736010
  Filename:       document.pdf
  Status:         Complete
  Progress:       100%
  Content Length: 12345 characters
```

## Implementation Instructions

When this command is invoked:

1. **Resolve Plugin Root**:
   ```bash
   if [[ -n "${RAG_PLUGIN_ROOT:-}" ]]; then
       SCRIPTS_PATH="${RAG_PLUGIN_ROOT}/skills/bubble-rag-orchestrator/scripts"
   elif [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
       SCRIPTS_PATH="${CLAUDE_PLUGIN_ROOT}/skills/bubble-rag-orchestrator/scripts"
   else
       echo "Error: Cannot locate plugin scripts"
       exit 1
   fi
   ```

2. **Parse Action and Arguments**: Extract from $ARGUMENTS:
   - `upload <file_path> [--kb <kb_id>]`
   - `list [--kb <kb_id>]`
   - `status <task_id> [--kb <kb_id>]`
   - `wait <task_id> [--kb <kb_id>]`
   - `delete <task_id> [--kb <kb_id>]`

3. **Execute Action**:

   **Upload:**
   ```bash
   source "${SCRIPTS_PATH}/doc_operations.sh"
   # Parse file_path and optional --kb
   file_path=$(echo "$ARGUMENTS" | sed 's/upload //' | sed 's/ --kb.*//')
   kb_id=""
   if [[ "$ARGUMENTS" == *"--kb"* ]]; then
       kb_id=$(echo "$ARGUMENTS" | sed -n 's/.*--kb[= ]\([^ ]*\).*/\1/p')
   fi
   doc_upload "$file_path" "$kb_id"
   ```

   **List:**
   ```bash
   source "${SCRIPTS_PATH}/doc_operations.sh"
   kb_id=""
   if [[ "$ARGUMENTS" == *"--kb"* ]]; then
       kb_id=$(echo "$ARGUMENTS" | sed -n 's/.*--kb[= ]\([^ ]*\).*/\1/p')
   fi
   doc_list_tasks "$kb_id"
   ```

   **Status:**
   ```bash
   source "${SCRIPTS_PATH}/doc_operations.sh"
   task_id=$(echo "$ARGUMENTS" | awk '{print $2}')
   kb_id=""
   if [[ "$ARGUMENTS" == *"--kb"* ]]; then
       kb_id=$(echo "$ARGUMENTS" | sed -n 's/.*--kb[= ]\([^ ]*\).*/\1/p')
   fi
   doc_task_status "$task_id" "$kb_id"
   ```

   **Wait:**
   ```bash
   source "${SCRIPTS_PATH}/doc_operations.sh"
   task_id=$(echo "$ARGUMENTS" | awk '{print $2}')
   kb_id=""
   if [[ "$ARGUMENTS" == *"--kb"* ]]; then
       kb_id=$(echo "$ARGUMENTS" | sed -n 's/.*--kb[= ]\([^ ]*\).*/\1/p')
   fi
   doc_wait_completion "$task_id" 300 5 "$kb_id"
   ```

   **Delete:**
   ```bash
   source "${SCRIPTS_PATH}/doc_operations.sh"
   task_id=$(echo "$ARGUMENTS" | awk '{print $2}')
   kb_id=""
   if [[ "$ARGUMENTS" == *"--kb"* ]]; then
       kb_id=$(echo "$ARGUMENTS" | sed -n 's/.*--kb[= ]\([^ ]*\).*/\1/p')
   fi
   doc_delete "$task_id" "$kb_id"
   ```

4. **Handle Status Codes**:
   - `split_status == 1` → Complete
   - `split_status == -1` → Processing
   - Other → Pending

## Processing Options

When uploading, documents are processed with these default settings:
- `chunk_size`: 1000 characters (configurable via `RAG_CHUNK_SIZE`)
- `data_clean`: Enabled (removes noise)
- `semantic_split`: Enabled (intelligent paragraph splitting)
- `small2big`: Enabled (hierarchical chunking)
- `graphing`: Disabled (knowledge graph construction)

## Tips

1. **Wait for processing**: Documents must complete processing before querying
2. **Check progress**: Use `/rag-doc status <task_id>` to monitor progress
3. **Large files**: Processing time depends on file size; typical files complete in 1-5 minutes
