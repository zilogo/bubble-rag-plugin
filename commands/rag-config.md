---
description: Configure Bubble RAG plugin settings including server URL, authentication, and defaults.
argument-hint: "[login|logout|set|reset] [args]"
model: claude-haiku-4-5-20251001
---

# RAG Configuration

Manage Bubble RAG plugin configuration and authentication.

## Usage

```
/rag-config                          # Show current configuration
/rag-config login [--server <url>]   # Login/register and save credentials
/rag-config logout                   # Clear saved credentials
/rag-config set <key> <value>        # Set configuration value
/rag-config reset                    # Reset to defaults
```

## Configuration Keys

| Key | Default | Description |
|-----|---------|-------------|
| RAG_SERVER_URL | http://localhost:8000 | Bubble RAG server URL |
| RAG_DEFAULT_KB | (none) | Default knowledge base ID |
| RAG_CHUNK_SIZE | 1000 | Document chunk size for upload |
| RAG_LIMIT_RESULT | 5 | Number of retrieval results |
| RAG_TIMEOUT | 60 | API timeout in seconds |

## Examples

```
/rag-config login --server http://192.168.1.100:8000
/rag-config set RAG_DEFAULT_KB 155878243264626698
/rag-config set RAG_CHUNK_SIZE 500
/rag-config logout
/rag-config reset
```

## Implementation Instructions

When this command is invoked:

1. **Resolve Plugin Root**: Find the plugin installation path
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

2. **Parse Action**: Determine the action from $ARGUMENTS:
   - No arguments or empty → Show config
   - `login` → Interactive login
   - `logout` → Clear credentials
   - `set <key> <value>` → Set config value
   - `reset` → Reset all config

3. **Execute Action**:

   **Show Config:**
   ```bash
   source "${SCRIPTS_PATH}/rag_utils.sh"
   config_list
   ```

   **Login:**
   ```bash
   source "${SCRIPTS_PATH}/auth.sh"
   # Parse --server flag if present
   server_url=""
   if [[ "$ARGUMENTS" == *"--server"* ]]; then
       server_url=$(echo "$ARGUMENTS" | sed -n 's/.*--server[= ]\([^ ]*\).*/\1/p')
   fi
   rag_interactive_login "$server_url"
   ```

   **Logout:**
   ```bash
   source "${SCRIPTS_PATH}/auth.sh"
   rag_logout
   ```

   **Set Config:**
   ```bash
   source "${SCRIPTS_PATH}/rag_utils.sh"
   # Extract key and value from: set <key> <value>
   key=$(echo "$ARGUMENTS" | awk '{print $2}')
   value=$(echo "$ARGUMENTS" | awk '{print $3}')
   config_set "$key" "$value"
   echo "Configuration updated: $key = $value"
   ```

   **Reset:**
   ```bash
   source "${SCRIPTS_PATH}/rag_utils.sh"
   config_reset
   ```

4. **Display Results**: Show confirmation and next steps to user.

## Security Notes

- Credentials are stored in `~/.bubble-rag/config` with 600 permissions
- Token is masked when displaying configuration
- Server URL is validated before login attempt
