# Module 8: Build Your Own — Hands-On Lab

> **Key Question:** Can I build all of this myself?

> **Duration:** 60 minutes
> **Prerequisites:** Modules 1-7, Python 3 installed

---

## Lab Overview

You will:
1. Build a custom MCP tool server (15 min)
2. Create an agent config that uses it (5 min)
3. Wire it into Kiro and test (10 min)
4. Add a new tool to your server (15 min)
5. Deploy to AWS (optional, 15 min)

---

## Lab 1: Build a Custom MCP Server (15 min)

### Step 1: Understand the protocol

An MCP server is a program that reads JSON-RPC from stdin and writes responses to stdout. It needs to handle three methods:

| Method | Purpose |
|--------|---------|
| `initialize` | Handshake |
| `tools/list` | Return available tools |
| `tools/call` | Execute a tool |

### Step 2: Examine the working example

```bash
cat hands-on/mcp-server/server.py
```

Key parts to notice:
- `handle_request()` — routes methods to handlers
- `tools/list` response — defines tool name, description, schema
- `tools/call` response — executes logic, returns result
- `main()` — reads stdin line by line, writes to stdout

### Step 3: Test it

```bash
# Handshake
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | python3 hands-on/mcp-server/server.py

# List tools
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | python3 hands-on/mcp-server/server.py

# Call get_system_info
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"get_system_info","arguments":{}}}' | python3 hands-on/mcp-server/server.py

# Call word_count
echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"word_count","arguments":{"text":"hello world test"}}}' | python3 hands-on/mcp-server/server.py
```

**Checkpoint:** You should see JSON responses for each command.

---

## Lab 2: Create an Agent Config (5 min)

### Step 1: Examine the agent config

```bash
cat hands-on/agent/demo-agent.json
```

Notice:
- `mcpServers.demo-tools.command` — points to your Python server
- `allowedTools` includes `@demo-tools` — auto-approves all tools from your server

### Step 2: Install it

```bash
cp hands-on/agent/demo-agent.json ~/.kiro/agents/demo-agent.json
```

**Checkpoint:** Run `/agent` in Kiro — you should see `demo-agent` in the list.

---

## Lab 3: Wire It In and Test (10 min)

### Step 1: Switch to your agent

```
/agent demo-agent
```

You should see: "Demo agent ready!"

### Step 2: Test your tools

```
What system am I running on?
```
→ Should call `get_system_info` from your MCP server.

```
Count the words in: The quick brown fox jumps over the lazy dog
```
→ Should call `word_count` from your MCP server.

### Step 3: Verify it's YOUR tool

Check `/tools` — you should see `@demo-tools/get_system_info` and `@demo-tools/word_count` listed.

**Checkpoint:** Both tools work through Kiro.

---

## Lab 4: Add a New Tool (15 min)

### Challenge: Add a `convert_temperature` tool

**Requirements:**
- Takes a number and a direction ("c_to_f" or "f_to_c")
- Returns the converted temperature

### Step 1: Add to tools/list

Open `hands-on/mcp-server/server.py` and add to the tools array:

```python
{
    "name": "convert_temperature",
    "description": "Convert temperature between Celsius and Fahrenheit. Use direction 'c_to_f' or 'f_to_c'.",
    "inputSchema": {
        "type": "object",
        "properties": {
            "value": {"type": "number", "description": "Temperature value"},
            "direction": {"type": "string", "enum": ["c_to_f", "f_to_c"], "description": "Conversion direction"}
        },
        "required": ["value", "direction"]
    }
}
```

### Step 2: Add the handler in tools/call

Add this after the `word_count` handler:

```python
elif name == "convert_temperature":
    value = args.get("value", 0)
    direction = args.get("direction", "c_to_f")
    if direction == "c_to_f":
        converted = (value * 9/5) + 32
        result = f"{value}°C = {converted}°F"
    else:
        converted = (value - 32) * 5/9
        result = f"{value}°F = {converted:.1f}°C"
```

### Step 3: Test manually

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"convert_temperature","arguments":{"value":100,"direction":"c_to_f"}}}' | python3 hands-on/mcp-server/server.py
```

Expected: `100°C = 212°F`

### Step 4: Test in Kiro

Switch away and back to reload the MCP server:
```
/agent kiro_default
/agent demo-agent
```

Then ask:
```
What is 37 degrees Celsius in Fahrenheit?
```

**Checkpoint:** Kiro uses YOUR `convert_temperature` tool and returns 98.6°F.

---

## Lab 5: Deploy to AWS (Optional, 15 min)

### Step 1: Create a Lambda wrapper

Create `hands-on/mcp-server/lambda_handler.py`:

```python
import json
from server import handle_request

def handler(event, context):
    body = json.loads(event.get("body", "{}"))
    result = handle_request(body)
    return {"statusCode": 200, "body": json.dumps(result), "headers": {"Content-Type": "application/json"}}
```

### Step 2: Deploy

```bash
cd hands-on/mcp-server
zip function.zip server.py lambda_handler.py

aws lambda create-function \
  --function-name mcp-demo-tools \
  --runtime python3.12 \
  --handler lambda_handler.handler \
  --zip-file fileb://function.zip \
  --role arn:aws:iam::<YOUR_ACCOUNT_ID>:role/<YOUR_LAMBDA_ROLE> \
  --region us-east-1

aws lambda create-function-url-config \
  --function-name mcp-demo-tools \
  --auth-type NONE \
  --region us-east-1
```

> **Note:** This uses `--auth-type NONE` for simplicity. For production, use `AWS_IAM` auth with SigV4 signing.

### Step 3: Update agent to use remote server

```json
{
  "mcpServers": {
    "demo-tools": {
      "url": "https://<your-lambda-url>.lambda-url.us-east-1.on.aws/"
    }
  }
}
```

**Checkpoint:** Same tools, now running on AWS.

---

## What You Built

```
┌─────────────────────────────────────────────────────────┐
│  YOUR CREATION:                                          │
│                                                          │
│  ┌──────────────┐     ┌──────────────────────────────┐  │
│  │ Agent Config  │     │ MCP Server (Python)           │  │
│  │ demo-agent   │────▶│ • get_system_info             │  │
│  │              │ MCP │ • word_count                   │  │
│  │ prompt       │     │ • convert_temperature          │  │
│  │ tools        │     │                                │  │
│  │ permissions  │     │ Speaks JSON-RPC over stdio     │  │
│  └──────────────┘     └──────────────────────────────┘  │
│         │                                                │
│         │ uses model                                     │
│         ▼                                                │
│  ┌──────────────┐                                        │
│  │ Claude       │  Understands your questions,           │
│  │ (Model)      │  picks the right tool,                 │
│  │              │  interprets results                    │
│  └──────────────┘                                        │
└─────────────────────────────────────────────────────────┘
```

---

## Concepts Covered in This Curriculum

| Module | Concept | One-liner |
|--------|---------|-----------|
| 1 | Agent | AI that can talk AND do things |
| 2 | Runtime vs Model | Orchestration vs intelligence |
| 3 | Tools | Functions the AI can call |
| 4 | Decision Making | Probabilistic tool selection via descriptions |
| 5 | Protocols | JSON-RPC, ACP (client↔agent), MCP (agent↔tools) |
| 6 | Memory | Context (short-term) + Knowledge (long-term) |
| 7 | Multi-Agent | DAGs for parallel coordination |
| 8 | Build Your Own | Custom MCP server + agent config |

---

## Expected Outcomes

After completing this lab, you should be able to:
- Build an MCP server from scratch that speaks JSON-RPC over stdio
- Define tools with names, descriptions, and parameter schemas
- Create an agent configuration that connects to your custom MCP server
- Test the full flow: agent receives your question, calls your tool, returns the result
- Add new tools to an existing MCP server and reload them in Kiro
- Describe the three-step deploy flow for AWS AgentCore (configure, test local, deploy)

---

## Check Your Understanding

1. What three JSON-RPC methods must an MCP server handle?
2. Why does the tool description matter more than the tool name?
3. What happens when you switch agents in Kiro — does the MCP server restart?
4. What is the difference between a local MCP server (stdio) and a remote one (HTTP)?
5. In the agent config, what does `allowedTools` do that `tools` does not?

---

## What's Next?

- **Explore agent configs:** Create specialized agents for your projects
- **Build more MCP tools:** Database queries, API integrations, custom workflows
- **Try subagent pipelines:** Ask Kiro complex comparison or audit tasks
- **Read the ACP spec:** [agentclientprotocol.com](https://agentclientprotocol.com/get-started/introduction)
- **Contribute:** Build MCP servers others can use

---

## Congratulations!

You now understand how AI agents work from the inside out. Not just theory — you built one.

---

## Next: Deploy to Production

Ready to take your agent to AWS? The Advanced track covers containerized deployment with Bedrock AgentCore.

Go to: [Bridge: From Kiro Agents to Production](../BRIDGE.md)
