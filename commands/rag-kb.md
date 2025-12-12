---
description: Manage Bubble RAG knowledge bases - create, list, delete, and configure.
argument-hint: "<action> [args]"
model: claude-haiku-4-5-20251001
---

# Knowledge Base Management

Manage your Bubble RAG knowledge bases.

## Usage

```
/rag-kb list                           # List all knowledge bases
/rag-kb create <name> [--desc <desc>]  # Create new knowledge base
/rag-kb delete <kb_id>                 # Delete a knowledge base
/rag-kb info <kb_id>                   # Get detailed info
/rag-kb use <kb_id>                    # Set as default knowledge base
/rag-kb clear                          # Clear default knowledge base
```

## Examples

```
/rag-kb list
/rag-kb create "Project Documentation" --desc "API and architecture docs"
/rag-kb create "FAQ Database"
/rag-kb info 155878243264626698
/rag-kb use 155878243264626698
/rag-kb delete 155878243264626698
/rag-kb clear
```

## Output Format

### List Output
```
Knowledge Bases
===============

ID                   Name                           Description                         Created
==============================================================================================================
155878243264626698   Project Documentation          API and architecture docs           2025-12-11T16:31:13 *
155993171623411721   FAQ Database                   -                                   2025-12-12T10:15:22

Total: 2 knowledge base(s)
* = default knowledge base
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

2. **Parse Action**: Extract the action from $ARGUMENTS:
   - `list` → List all knowledge bases
   - `create <name> [--desc <desc>]` → Create new KB
   - `delete <kb_id>` → Delete KB
   - `info <kb_id>` → Show KB details
   - `use <kb_id>` → Set default KB
   - `clear` → Clear default KB

3. **Execute Action**:

   **List:**
   ```bash
   source "${SCRIPTS_PATH}/kb_operations.sh"
   kb_list
   ```

   **Create:**
   ```bash
   source "${SCRIPTS_PATH}/kb_operations.sh"
   # Parse name and optional --desc
   name=$(echo "$ARGUMENTS" | sed 's/create //' | sed 's/ --desc.*//')
   desc=""
   if [[ "$ARGUMENTS" == *"--desc"* ]]; then
       desc=$(echo "$ARGUMENTS" | sed -n 's/.*--desc[= ]\(.*\)/\1/p')
   fi
   kb_create "$name" "$desc"
   ```

   **Delete:**
   ```bash
   source "${SCRIPTS_PATH}/kb_operations.sh"
   kb_id=$(echo "$ARGUMENTS" | awk '{print $2}')
   kb_delete "$kb_id"
   ```

   **Info:**
   ```bash
   source "${SCRIPTS_PATH}/kb_operations.sh"
   kb_id=$(echo "$ARGUMENTS" | awk '{print $2}')
   kb_info "$kb_id"
   ```

   **Use:**
   ```bash
   source "${SCRIPTS_PATH}/kb_operations.sh"
   kb_id=$(echo "$ARGUMENTS" | awk '{print $2}')
   kb_use "$kb_id"
   ```

   **Clear:**
   ```bash
   source "${SCRIPTS_PATH}/kb_operations.sh"
   kb_clear_default
   ```

4. **Handle Errors**: Display appropriate error messages and suggestions.

## Important Notes

- **Delete is irreversible**: Deleting a knowledge base removes all documents and embeddings
- **Default KB**: Setting a default saves time when querying with `/rag`
- **Model IDs**: KB creation uses default Rerank (154605956896915473) and Embedding (154605669335433233) models
