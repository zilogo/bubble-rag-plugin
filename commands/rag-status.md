---
description: Check Bubble RAG service status and connectivity.
argument-hint: ""
model: claude-haiku-4-5-20251001
---

# RAG Status

Check the status of Bubble RAG service and your configuration.

## Usage

```
/rag-status
```

## Output

The command displays:
- Server URL and connectivity status
- Authentication status
- Current username (if authenticated)
- Default knowledge base (if set)
- Configuration file location

## Example Output

```
Bubble RAG Status
=================

Server URL:     http://192.168.1.100:8000
Server Status:  Connected
Authentication: Authenticated
Username:       your_username
Default KB:     155878243264626698

Config File:    ~/.bubble-rag/config
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

2. **Run Status Check**:
   ```bash
   source "${SCRIPTS_PATH}/rag_utils.sh"
   check_status
   ```

3. **Additional Checks** (optional):
   - If authenticated, verify token is still valid
   - If default KB is set, verify it still exists

## Troubleshooting

| Status | Solution |
|--------|----------|
| Server: Disconnected | Check server URL with `/rag-config set RAG_SERVER_URL <url>` |
| Not authenticated | Run `/rag-config login` |
| Default KB not set | Run `/rag-kb use <kb_id>` |
