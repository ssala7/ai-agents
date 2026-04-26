# Troubleshooting — Common Problems and Fixes

Quick reference for issues you may hit while working through the curriculum.

---

## Kiro CLI

### Kiro command not found
```
kiro-cli: command not found
```
Kiro is not installed or not in your PATH.
- macOS: `brew install kiro-cli`
- Linux: `curl -fsSL https://kiro.dev/install.sh | bash`
- Then restart your terminal.

### Agent not responding / hanging
The model API may be slow or unreachable.
- Check your internet connection
- Try a different model: `/model` then select another option
- If using Bedrock, verify model access is enabled in the AWS Console

### "Conversation too short to compact"
You ran `/compact` but there is not enough history to summarize. Keep chatting and try again later.

### Context window full
The model starts forgetting or giving confused answers.
- Run `/context` to check usage
- Run `/compact` to summarize and free space
- Run `/clear` to wipe and start fresh (loses history)

### Tool permission prompts are annoying
Every tool call asks "Allow?".
- `/tools trust-all` — auto-approve everything (use during learning, not production)
- `/tools trust fs_read` — trust specific safe tools
- `/tools reset` — restore prompts when done

---

## MCP Server (Module 5, 8)

### Python server returns nothing
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | python3 hands-on/mcp-server/server.py
```
If no output appears:
- Check Python version: `python3 --version` (need 3.11+)
- Check the file path is correct (run from the repo root)
- Check for syntax errors: `python3 hands-on/mcp-server/server.py` with manual input

### MCP server not connecting in Kiro
After `/agent demo-agent`, tools from `@demo-tools` are not available.
- Check the path in `demo-agent.json` — it must be relative to where you started Kiro
- Run `/mcp` to see if the server is listed and its status
- Try an absolute path in the agent config temporarily

### "Unknown tool" error from MCP server
You called a tool that does not exist on the server.
- Run `tools/list` to see available tools
- Check spelling — tool names are case-sensitive

---

## Agent Configuration (Module 8)

### Agent not showing in /agent list
- Check the file is in `~/.kiro/agents/` (global) or `.kiro/agents/` (local)
- File must end in `.json`
- File must contain valid JSON — validate with: `python3 -m json.tool ~/.kiro/agents/demo-agent.json`

### Agent config validation error
```
Agent config is malformed
```
- Run `kiro-cli agent validate --path ~/.kiro/agents/demo-agent.json`
- Common issues: missing commas, trailing commas, wrong field names

### Tools not available after switching agent
- MCP servers need time to initialize after agent switch
- Run `/mcp` to check server status
- If stuck, switch away and back: `/agent kiro_default` then `/agent demo-agent`

---

## Knowledge Base (Module 6)

### "Knowledge feature not enabled"
```bash
kiro-cli settings chat.enableKnowledge true
```
Then restart your Kiro session.

### Search returns no results
- Verify content was indexed: `/knowledge show`
- Try different search terms — semantic search matches meaning, not exact words
- If using Fast (BM25) mode, use exact keywords instead of natural language

### Indexing is slow
Large directories take time. Use more specific paths:
```
/knowledge add api-code src/api/     # better than indexing all of src/
```

---

## AWS Deployment (Advanced Track)

### `agentcore: command not found`
Activate the virtual environment first:
```bash
source agentcore-deploy/.venv/bin/activate
```

### `AccessDeniedException` when invoking model
Bedrock model access is not enabled.
1. AWS Console --> Bedrock --> Model access
2. Enable the model you are using (e.g., Amazon Nova Lite)
3. Wait ~1 minute for access to propagate

### Docker errors
```
Cannot connect to the Docker daemon
```
Start Docker Desktop and retry.

### ECR push fails with auth error
Re-authenticate:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  $(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com
```

### Endpoint stuck in CREATING state
Check CloudWatch logs for errors:
```bash
aws logs tail /aws/bedrock-agentcore/ --follow
```
Common causes: missing IAM permissions, model not enabled, container crash.

---

## General Tips

- When something fails, read the error message carefully. Most Kiro errors include a suggestion.
- Use `/guide <question>` to ask Kiro about itself — it searches its own documentation.
- Check `/tools` and `/mcp` to verify what is available before assuming something is broken.
- If a module exercise does not produce the expected output, re-read the "Expected output" section and compare carefully.
