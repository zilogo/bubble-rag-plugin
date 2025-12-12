# Troubleshooting Guide

## Common Issues

### Authentication Issues

#### "Not authenticated" error

**Cause**: No valid authentication token stored.

**Solution**:
```
/rag-config login --server http://your-server:8000
```

#### "Token expired or invalid" error

**Cause**: Authentication token has expired.

**Solution**:
```
/rag-config logout
/rag-config login
```

#### "Authentication failed" during login

**Cause**: Incorrect username/password or server issue.

**Solution**:
1. Verify username and password
2. Check server URL is correct
3. Verify server is running: `curl http://your-server:8000/health`

### Connection Issues

#### "Server disconnected" status

**Cause**: Cannot reach the Bubble RAG server.

**Solutions**:

1. **Check server URL**:
   ```
   /rag-status
   ```

2. **Update server URL if incorrect**:
   ```
   /rag-config set RAG_SERVER_URL http://correct-server:8000
   ```

3. **Test connectivity**:
   ```bash
   curl http://your-server:8000/health
   ```

4. **Check network/firewall**:
   - Ensure port 8000 is accessible
   - Check VPN if required
   - Verify no firewall blocking

#### "Connection timeout" error

**Cause**: Server is slow to respond or unreachable.

**Solution**:
1. Increase timeout:
   ```
   /rag-config set RAG_TIMEOUT 120
   ```
2. Check server load
3. Try again later

### Knowledge Base Issues

#### "No knowledge base specified"

**Cause**: No default KB set and no `--kb` flag provided.

**Solutions**:

1. **Specify KB in command**:
   ```
   /rag "question" --kb <kb_id>
   ```

2. **Set default KB**:
   ```
   /rag-kb list
   /rag-kb use <kb_id>
   ```

#### "Knowledge base not found"

**Cause**: The specified KB ID doesn't exist.

**Solution**:
1. List available KBs:
   ```
   /rag-kb list
   ```
2. Use correct ID from the list

#### Empty results when querying

**Cause**: No matching documents or documents not processed.

**Solutions**:

1. **Check document status**:
   ```
   /rag-doc list
   ```
   Ensure `Status` is `Complete`.

2. **Verify documents exist**:
   Upload documents if KB is empty.

3. **Try broader query**:
   Use more general terms.

### Document Upload Issues

#### "File not found" error

**Cause**: File path is incorrect or file doesn't exist.

**Solution**:
1. Use absolute path: `/rag-doc upload /full/path/to/file.pdf`
2. Verify file exists: `ls -la /path/to/file.pdf`

#### "Upload failed" error

**Cause**: Server rejected the upload.

**Solutions**:

1. **Check file size**: Large files may fail
2. **Check file format**: Supported formats are `.txt`, `.pdf`, `.docx`
3. **Check server logs** for detailed error

#### Document stuck in "Processing" state

**Cause**: Processing is slow or failed silently.

**Solutions**:

1. **Check status**:
   ```
   /rag-doc status <task_id>
   ```

2. **Wait longer** - large documents take more time

3. **Check server resources** - processing may be queued

4. **Re-upload** if stuck for extended period

### Configuration Issues

#### "Cannot locate plugin scripts" error

**Cause**: Plugin environment not properly initialized.

**Solutions**:

1. **Restart Claude Code**

2. **Check plugin installation**:
   ```bash
   claude plugins list
   ```

3. **Reinstall plugin**:
   ```bash
   claude plugins uninstall bubble-rag-plugin
   claude plugins install github:zilogo/bubble-rag-plugin
   ```

#### Configuration not persisting

**Cause**: Permission issues with config file.

**Solution**:
```bash
# Check permissions
ls -la ~/.bubble-rag/

# Fix permissions
chmod 700 ~/.bubble-rag
chmod 600 ~/.bubble-rag/config
```

### Script Execution Issues

#### "Permission denied" when running commands

**Cause**: Script files don't have execute permission.

**Solution**:
```bash
# Find and fix permissions
find ~/.claude/plugins -name "*.sh" -exec chmod +x {} \;
```

#### "jq: command not found"

**Cause**: jq JSON processor not installed.

**Solution**:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# CentOS/RHEL
sudo yum install jq
```

#### "curl: command not found"

**Cause**: curl not installed.

**Solution**:
```bash
# macOS (usually pre-installed)
brew install curl

# Ubuntu/Debian
sudo apt install curl

# CentOS/RHEL
sudo yum install curl
```

## Diagnostic Commands

### Check overall status

```
/rag-status
```

### View current configuration

```
/rag-config
```

### Test API connectivity

```bash
# Health check
curl http://your-server:8000/health

# API endpoint test (requires token)
curl -X POST http://your-server:8000/bubble_rag/api/v1/knowledge_base/list_knowledge_base \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"page_num": 1, "page_size": 10}'
```

### Check plugin installation

```bash
claude plugins list
```

### View config file

```bash
cat ~/.bubble-rag/config
```

## Getting Help

### In-app help

```
/rag-help
/rag-help <command>
```

### Log files

Check Claude Code logs for detailed error messages.

### Support

- **Repository**: https://github.com/zilogo/bubble-rag-plugin
- **Issues**: https://github.com/zilogo/bubble-rag-plugin/issues

## Reset Everything

If all else fails, start fresh:

```bash
# Remove configuration
rm -rf ~/.bubble-rag

# Reinstall plugin
claude plugins uninstall bubble-rag-plugin
claude plugins install github:zilogo/bubble-rag-plugin

# Reconfigure
/rag-config login --server http://your-server:8000
```
