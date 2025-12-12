# Installation Guide

## Prerequisites

Before installing the Bubble RAG plugin, ensure you have:

1. **Claude Code CLI** installed and configured
2. **curl** command-line tool
3. **jq** JSON processor
4. Access to a **Bubble RAG server**

### Installing Dependencies

**macOS:**
```bash
brew install curl jq
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install curl jq
```

**CentOS/RHEL:**
```bash
sudo yum install curl jq
```

## Installation Methods

### Method 1: From GitHub (Recommended)

```bash
claude plugins install github:laiye-ai/bubble-rag-plugin
```

### Method 2: From Local Directory

If you have the plugin source code locally:

```bash
claude plugins install /path/to/bubble-rag-plugin
```

### Method 3: Development Installation

For development or testing:

```bash
# Clone the repository
git clone https://github.com/laiye-ai/bubble-rag-plugin.git
cd bubble-rag-plugin

# Install locally
claude plugins install .
```

## Verification

After installation, verify the plugin is loaded:

```bash
# Check plugin status
claude plugins list

# Or use the plugin command
/rag-status
```

## Initial Configuration

### Step 1: Login to your server

```
/rag-config login --server http://your-server:8000
```

You'll be prompted for:
- **Username**: Your Bubble RAG username
- **Password**: Your password (default: `laiye123` for new accounts)

### Step 2: Verify connection

```
/rag-status
```

Expected output:
```
Bubble RAG Status
=================

Server URL:     http://your-server:8000
Server Status:  Connected
Authentication: Authenticated
Username:       your_username
```

### Step 3: Set up a knowledge base

List existing knowledge bases:
```
/rag-kb list
```

Or create a new one:
```
/rag-kb create "My Knowledge Base" --desc "Description here"
```

### Step 4: Set default knowledge base

```
/rag-kb use <kb_id>
```

## Configuration File

The plugin stores configuration in `~/.bubble-rag/config`:

```bash
# View config file
cat ~/.bubble-rag/config

# Example content:
RAG_SERVER_URL="http://your-server:8000"
RAG_TOKEN="eyJhbGci..."
RAG_USERNAME="your_username"
RAG_DEFAULT_KB="155878243264626698"
```

## Updating the Plugin

```bash
# Update to latest version
claude plugins update bubble-rag-plugin
```

## Uninstalling

```bash
# Remove the plugin
claude plugins uninstall bubble-rag-plugin

# Optionally remove configuration
rm -rf ~/.bubble-rag
```

## Troubleshooting Installation

### Plugin not found after installation

Try restarting Claude Code or running:
```bash
claude plugins list
```

### Permission denied errors

Ensure the scripts have execute permission:
```bash
chmod +x ~/.claude/plugins/*/bubble-rag-plugin/*/hooks/*.sh
chmod +x ~/.claude/plugins/*/bubble-rag-plugin/*/skills/*/scripts/*.sh
```

### Dependencies missing

Install required tools:
```bash
# Check if curl is installed
which curl || echo "curl not found"

# Check if jq is installed
which jq || echo "jq not found"
```

### Server connection failed

1. Verify server URL is correct
2. Check network connectivity
3. Ensure server is running
4. Check firewall settings

## Next Steps

After installation:

1. Upload your first document: `/rag-doc upload /path/to/file.pdf`
2. Query your knowledge base: `/rag "Your question here"`
3. Explore help: `/rag-help`
