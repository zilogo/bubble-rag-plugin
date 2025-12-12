---
description: Query your knowledge base using Bubble RAG semantic search and intelligent Q&A.
argument-hint: "<question> [--kb <kb_id>]"
model: claude-sonnet-4-5-20250929
---

# RAG Query

Perform semantic search and intelligent Q&A against your configured knowledge base.

## Usage

```
/rag "<question>"
/rag "<question>" --kb <knowledge_base_id>
```

## Examples

```
/rag "How does authentication work in this project?"
/rag "What are the main API endpoints?"
/rag "Summarize the deployment process"
/rag "Explain the database schema" --kb 155878243264626698
```

## Knowledge Base Selection

The command determines which knowledge base to use in this order:

1. **Explicit `--kb` flag**: If provided, uses that specific KB
2. **Default KB**: Uses `RAG_DEFAULT_KB` from config if set
3. **Single KB**: If only one KB exists, uses it automatically
4. **Multiple KBs**: Lists available KBs and prompts for selection

### Setting a Default KB

```
/rag-kb use 155878243264626698
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

2. **Check Authentication**:
   ```bash
   source "${SCRIPTS_PATH}/rag_utils.sh"
   if ! check_auth; then
       echo "Not authenticated. Please run '/rag-config login' first."
       exit 1
   fi
   ```

3. **Parse Arguments**: Extract the question and optional --kb flag from $ARGUMENTS
   ```bash
   # Extract question (everything before --kb or the entire argument)
   question=$(echo "$ARGUMENTS" | sed 's/ --kb.*//')

   # Extract optional --kb value
   kb_id=""
   if [[ "$ARGUMENTS" == *"--kb"* ]]; then
       kb_id=$(echo "$ARGUMENTS" | sed -n 's/.*--kb[= ]\([^ ]*\).*/\1/p')
   fi
   ```

4. **Determine Knowledge Base**: If no --kb provided, use smart selection
   ```bash
   source "${SCRIPTS_PATH}/api_client.sh"

   if [[ -z "$kb_id" ]]; then
       # Try to get or select KB
       kb_id=$(get_or_select_kb "")

       # If selection needed (exit code 2), show list and stop
       if [[ $? -eq 2 ]]; then
           # User needs to specify KB - message already shown
           exit 0
       fi
   fi
   ```

5. **Execute Query**:
   ```bash
   source "${SCRIPTS_PATH}/api_client.sh"

   # Get config values
   limit_result=$(config_get "RAG_LIMIT_RESULT" "5")

   # Execute RAG chat
   answer=$(rag_chat "$question" "$kb_id" "$limit_result")

   if [[ $? -eq 0 ]]; then
       echo ""
       echo "Answer:"
       echo "======="
       echo ""
       echo "$answer"
       echo ""
   fi
   ```

6. **Display Results**: Present the AI-generated answer to the user with clear formatting.

## Response Format

The response includes:
- AI-generated answer based on retrieved documents
- Reasoning process (may include `<think>` tags which are filtered)
- Token usage statistics (in API response)

## Error Handling

| Error | Solution |
|-------|----------|
| Not authenticated | Run `/rag-config login` |
| No KB specified | Use `--kb` flag or set default with `/rag-kb use` |
| KB not found | Verify KB ID with `/rag-kb list` |
| No documents | Upload documents with `/rag-doc upload` |

## Tips

1. **Be specific**: More specific questions get better answers
2. **Use context**: Reference specific topics or sections if known
3. **Check KB first**: Ensure your KB has relevant documents with `/rag-doc list`

## Advanced Options

Configure these in `~/.bubble-rag/config`:

| Setting | Default | Description |
|---------|---------|-------------|
| RAG_LIMIT_RESULT | 5 | Number of documents to retrieve |
| RAG_TIMEOUT | 60 | Query timeout in seconds |
