# Hands-On: Build a Custom Tool & Deploy to AWS

This is a practical walkthrough. No theory — just do it and see it work.

---

## Part 1: Your Custom MCP Tool (5 minutes)

### What you built

`mcp-server/server.py` is a custom MCP server with 2 tools:
- `get_system_info` — returns OS, time, disk usage
- `word_count` — counts words/lines/chars in text

### Test it manually

```bash
# Send a tools/list request to see what tools are available
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | python3 kiro-concepts-demo/hands-on/mcp-server/server.py
```

Expected output:
```json
{"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"get_system_info",...},{"name":"word_count",...}]}}
```

### Call a tool manually

```bash
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_system_info","arguments":{}}}' | python3 kiro-concepts-demo/hands-on/mcp-server/server.py
```

You'll see your OS, current time, and disk usage.

```bash
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"word_count","arguments":{"text":"hello world this is a test"}}}' | python3 kiro-concepts-demo/hands-on/mcp-server/server.py
```

You'll see: Words: 6, Lines: 1, Chars: 26

---

## Part 2: Wire It Into Kiro (2 minutes)

### Option A: Copy agent to your agents folder

```bash
cp kiro-concepts-demo/hands-on/agent/demo-agent.json ~/.kiro/agents/demo-agent.json
```

Then in Kiro:
```
/agent demo-agent
```

### Option B: Add MCP server to your current agent

```bash
kiro-cli mcp add --name demo-tools --command python3 --args ./kiro-concepts-demo/hands-on/mcp-server/server.py
```

### Try it

Once the agent is active, ask:
```
What system am I running on?
```
→ It will call `get_system_info` and show you the result.

```
Count the words in: The quick brown fox jumps over the lazy dog
```
→ It will call `word_count` and return the analysis.

---

## Part 3: How MCP Protocol Works (What You Just Saw)

```
┌──────────┐    stdin (JSON-RPC)     ┌──────────────┐
│   Kiro   │ ──────────────────────▶ │  Your Python │
│  Agent   │ ◀────────────────────── │  MCP Server  │
└──────────┘    stdout (JSON-RPC)    └──────────────┘
```

The protocol is simple:
1. Kiro sends `initialize` → server responds with capabilities
2. Kiro sends `tools/list` → server responds with available tools
3. Kiro sends `tools/call` with tool name + arguments → server responds with result

That's it. Three message types and you have a custom tool.

---

## Part 4: Make Your Own Tool

Want to add a new tool? Edit `server.py`:

### Step 1: Add to tools/list

```python
{
    "name": "my_new_tool",
    "description": "Does something cool",
    "inputSchema": {
        "type": "object",
        "properties": {
            "input_param": {"type": "string", "description": "What to process"}
        },
        "required": ["input_param"]
    }
}
```

### Step 2: Handle in tools/call

```python
elif name == "my_new_tool":
    param = args.get("input_param", "")
    result = f"Processed: {param}"  # your logic here
```

### Step 3: Restart

Kiro reconnects to the MCP server automatically. Or switch away and back:
```
/agent kiro_default
/agent demo-agent
```

---

## Part 5: Deploy to AWS Bedrock

### What Bedrock Gives You

AWS Bedrock lets you run foundation models (Claude, Llama, etc.) as an API. You can use Bedrock as the model backend for Kiro agents, and deploy your MCP tools alongside.

### Architecture on AWS

```
┌─────────────────────────────────────────────────────┐
│  Your AWS Account                                    │
│                                                      │
│  ┌──────────────┐     ┌──────────────────────────┐  │
│  │ Bedrock      │     │ Your MCP Server           │  │
│  │ (Claude API) │     │ (Lambda / ECS / EC2)      │  │
│  └──────┬───────┘     └────────────┬─────────────┘  │
│         │                          │                 │
└─────────┼──────────────────────────┼─────────────────┘
          │                          │
          ▼                          ▼
┌─────────────────────────────────────────────────────┐
│  Kiro CLI (your machine)                             │
│  • Uses Bedrock as model                             │
│  • Connects to remote MCP server via HTTP            │
└─────────────────────────────────────────────────────┘
```

### Step 1: Enable Bedrock Model Access

```bash
# Check available models in your region
aws bedrock list-foundation-models --region us-east-1 --query "modelSummaries[?contains(modelId,'claude')].[modelId,modelName]" --output table
```

Enable model access in the AWS Console:
→ Bedrock → Model access → Request access to Claude models

### Step 2: Deploy MCP Server as Lambda (simplest)

Create a Lambda-compatible version of your MCP server:

```python
# lambda_handler.py
import json
from server import handle_request

def handler(event, context):
    """Lambda wrapper for MCP server — handles HTTP requests."""
    body = json.loads(event.get("body", "{}"))
    result = handle_request(body)
    return {
        "statusCode": 200,
        "body": json.dumps(result),
        "headers": {"Content-Type": "application/json"}
    }
```

Deploy:
```bash
# Zip and deploy
cd kiro-concepts-demo/hands-on/mcp-server
zip function.zip server.py lambda_handler.py

aws lambda create-function \
  --function-name mcp-demo-tools \
  --runtime python3.12 \
  --handler lambda_handler.handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::<ACCOUNT_ID>:role/lambda-basic-role \
  --region us-east-1

# Add a function URL for HTTP access
aws lambda create-function-url-config \
  --function-name mcp-demo-tools \
  --auth-type AWS_IAM \
  --region us-east-1
```

### Step 3: Point Kiro Agent at Remote MCP Server

Update your agent config to use the remote server:

```json
{
  "name": "demo-agent-aws",
  "description": "Demo agent with AWS-hosted MCP tools",
  "prompt": "You are a helpful assistant with custom tools hosted on AWS.",
  "tools": ["fs_read", "execute_bash"],
  "mcpServers": {
    "demo-tools": {
      "url": "https://<your-lambda-url>.lambda-url.us-east-1.on.aws/",
      "headers": {
        "Authorization": "Bearer $AWS_SESSION_TOKEN"
      }
    }
  }
}
```

### Step 4: Use Bedrock as the Model

Configure Kiro to use Bedrock:
```bash
kiro-cli settings set default_model bedrock/<model-id>
```

Or in agent config:
```json
{
  "name": "demo-agent-aws",
  "model": "bedrock/<model-id>"
}
```

---

## Summary: What You Learned

| Step | What | Why |
|------|------|-----|
| 1 | Built an MCP server | Custom tools = MCP servers |
| 2 | Wired it into Kiro | Agent config → mcpServers |
| 3 | Tested locally | stdio transport (stdin/stdout) |
| 4 | Deployed to Lambda | Remote MCP via HTTP |
| 5 | Connected to Bedrock | AWS-hosted model backend |

### The mental model:

```
Tool = a function exposed by an MCP server
Agent = config that says which tools + model to use
Kiro = the runtime that connects agents to tools and models
Bedrock = one possible model backend (runs in your AWS account)
```
