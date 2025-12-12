---
description: Display comprehensive help information for the Bubble RAG plugin.
argument-hint: "[command]"
model: claude-haiku-4-5-20251001
---

# RAG Help

Display help information for Bubble RAG plugin commands.

## Usage

```
/rag-help              # Show all commands overview
/rag-help <command>    # Show detailed help for specific command
```

## Examples

```
/rag-help
/rag-help rag
/rag-help rag-kb
/rag-help rag-doc
/rag-help rag-config
```

## Implementation Instructions

When this command is invoked, display the following help information:

### Overview (no arguments)

```markdown
# Bubble RAG Plugin - Help

Enterprise RAG integration for Claude Code with knowledge base management,
document upload, and intelligent Q&A retrieval.

## Quick Start

1. Configure and login:
   /rag-config login --server http://your-server:8000

2. Create a knowledge base:
   /rag-kb create "My Knowledge Base"

3. Upload documents:
   /rag-doc upload /path/to/document.pdf

4. Wait for processing:
   /rag-doc wait <task_id>

5. Query your knowledge:
   /rag "What does this document explain?"

## Available Commands

| Command | Description |
|---------|-------------|
| /rag "<question>" | Query knowledge base with semantic search |
| /rag-kb | Manage knowledge bases (list, create, delete, use) |
| /rag-doc | Manage documents (upload, list, status, wait) |
| /rag-config | Configure settings and authentication |
| /rag-status | Check service status and connectivity |
| /rag-help | Display this help information |

## Command Details

### /rag - Query Knowledge Base
```
/rag "<question>"                    # Query using default KB
/rag "<question>" --kb <kb_id>       # Query specific KB
```

### /rag-kb - Knowledge Base Management
```
/rag-kb list                         # List all knowledge bases
/rag-kb create <name> [--desc ...]   # Create new KB
/rag-kb delete <kb_id>               # Delete KB (irreversible!)
/rag-kb info <kb_id>                 # Show KB details
/rag-kb use <kb_id>                  # Set as default KB
/rag-kb clear                        # Clear default KB
```

### /rag-doc - Document Management
```
/rag-doc upload <file> [--kb ...]    # Upload document
/rag-doc list [--kb ...]             # List document tasks
/rag-doc status <task_id>            # Check processing status
/rag-doc wait <task_id>              # Wait for completion
/rag-doc delete <task_id>            # Delete document task
```

### /rag-config - Configuration
```
/rag-config                          # Show current config
/rag-config login [--server ...]     # Login to server
/rag-config logout                   # Clear credentials
/rag-config set <key> <value>        # Set config value
/rag-config reset                    # Reset to defaults
```

## Configuration

Settings are stored in `~/.bubble-rag/config`:

| Key | Default | Description |
|-----|---------|-------------|
| RAG_SERVER_URL | http://localhost:8000 | Server URL |
| RAG_DEFAULT_KB | (none) | Default knowledge base |
| RAG_CHUNK_SIZE | 1000 | Document chunk size |
| RAG_LIMIT_RESULT | 5 | Retrieval result limit |
| RAG_TIMEOUT | 60 | API timeout (seconds) |

## Troubleshooting

### "Not authenticated"
Run `/rag-config login` to authenticate.

### "No knowledge base specified"
Either:
- Use `--kb <id>` flag
- Set default with `/rag-kb use <id>`

### "Server disconnected"
Check server URL with `/rag-status` and update if needed.

### "Document not ready"
Wait for document processing to complete:
- Check with `/rag-doc status <task_id>`
- Wait with `/rag-doc wait <task_id>`

## Support

- Repository: https://github.com/laiye-ai/bubble-rag-plugin
- Issues: https://github.com/laiye-ai/bubble-rag-plugin/issues
```

### Specific Command Help

When a specific command is provided (e.g., `/rag-help rag-kb`), display detailed help for that command including all subcommands, options, and examples.

## Notes

- This command uses Haiku for fast response
- Help content is static and doesn't require API calls
- Consider user's current authentication state when showing relevant tips
