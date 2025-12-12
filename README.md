# Bubble RAG Plugin for Claude Code

Enterprise RAG (Retrieval-Augmented Generation) integration for Claude Code. Manage knowledge bases, upload documents, and perform intelligent Q&A retrieval directly from your IDE.

## Features

- **Knowledge Base Management**: Create, list, delete, and configure knowledge bases
- **Document Upload**: Upload and process documents with semantic splitting
- **Intelligent Q&A**: Query your documents with natural language
- **Smart KB Selection**: Automatic knowledge base selection when not specified
- **Configuration Management**: Easy setup and configuration

## Installation

### From GitHub

```bash
claude plugins install github:laiye-ai/bubble-rag-plugin
```

### From Local Directory

```bash
claude plugins install /path/to/bubble-rag-plugin
```

## Quick Start

### 1. Login to your Bubble RAG server

```
/rag-config login --server http://your-server:8000
```

Enter your username and password when prompted.

### 2. Create a knowledge base

```
/rag-kb create "My Documentation" --desc "Project documentation"
```

### 3. Upload documents

```
/rag-doc upload /path/to/document.pdf
```

### 4. Wait for processing

```
/rag-doc wait <task_id>
```

### 5. Query your knowledge

```
/rag "What does this document explain?"
```

## Commands

| Command | Description |
|---------|-------------|
| `/rag "<question>"` | Query knowledge base with semantic search |
| `/rag-kb` | Manage knowledge bases (list, create, delete, use) |
| `/rag-doc` | Manage documents (upload, list, status, wait) |
| `/rag-config` | Configure settings and authentication |
| `/rag-status` | Check service status and connectivity |
| `/rag-help` | Display help information |

## Command Reference

### /rag - Query Knowledge Base

```bash
/rag "Your question here"
/rag "Your question" --kb <kb_id>  # Query specific KB
```

### /rag-kb - Knowledge Base Management

```bash
/rag-kb list                           # List all KBs
/rag-kb create <name> [--desc <desc>]  # Create KB
/rag-kb delete <kb_id>                 # Delete KB
/rag-kb info <kb_id>                   # KB details
/rag-kb use <kb_id>                    # Set default KB
/rag-kb clear                          # Clear default
```

### /rag-doc - Document Management

```bash
/rag-doc upload <file> [--kb <kb_id>]  # Upload document
/rag-doc list [--kb <kb_id>]           # List tasks
/rag-doc status <task_id>              # Check status
/rag-doc wait <task_id>                # Wait for completion
/rag-doc delete <task_id>              # Delete task
```

### /rag-config - Configuration

```bash
/rag-config                            # Show config
/rag-config login [--server <url>]     # Login
/rag-config logout                     # Logout
/rag-config set <key> <value>          # Set value
/rag-config reset                      # Reset all
```

## Configuration

Settings are stored in `~/.bubble-rag/config`:

| Key | Default | Description |
|-----|---------|-------------|
| `RAG_SERVER_URL` | http://localhost:8000 | Bubble RAG server URL |
| `RAG_DEFAULT_KB` | (none) | Default knowledge base ID |
| `RAG_CHUNK_SIZE` | 1000 | Document chunk size |
| `RAG_LIMIT_RESULT` | 5 | Number of retrieval results |
| `RAG_TIMEOUT` | 60 | API timeout (seconds) |

## Supported File Formats

- Text files: `.txt`
- Office documents: `.docx`, `.doc`
- PDF documents: `.pdf`

## Smart Knowledge Base Selection

When you run `/rag` without specifying a knowledge base:

1. **Default KB set**: Uses the configured default
2. **Single KB exists**: Automatically uses it
3. **Multiple KBs**: Lists available options for selection

Set a default with:
```
/rag-kb use <kb_id>
```

## Requirements

- Claude Code CLI
- `curl` command-line tool
- `jq` JSON processor
- Access to a Bubble RAG server

## Troubleshooting

### "Not authenticated"

Run `/rag-config login` to authenticate with your server.

### "Server disconnected"

Check your server URL with `/rag-status` and update if needed:
```
/rag-config set RAG_SERVER_URL http://correct-server:8000
```

### "No knowledge base specified"

Either specify with `--kb` flag or set a default:
```
/rag-kb use <kb_id>
```

### Document processing stuck

Check status with `/rag-doc status <task_id>`. Processing time depends on file size.

## Security

- Credentials stored in `~/.bubble-rag/config` with 600 permissions
- Tokens transmitted via Authorization header
- No sensitive data logged

## API Compatibility

This plugin is compatible with Bubble RAG API v1. Default model IDs:
- Rerank Model: `154605956896915473` (Qwen3-Reranker-4B)
- Embedding Model: `154605669335433233` (Qwen3-Embedding-0.6B)

## License

MIT License

## Support

- Repository: https://github.com/laiye-ai/bubble-rag-plugin
- Issues: https://github.com/laiye-ai/bubble-rag-plugin/issues
