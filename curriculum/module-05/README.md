# Module 5: Protocols — ACP & JSON-RPC

> **Key Question:** How do all the components talk to each other?

---

## 5.1 Why Protocols Matter

An agent has many parts: client (UI), runtime, model, tools, MCP servers. They all need a common language.

```
Without a protocol:
  Client: "hey do the thing"
  Runtime: "what format is this? I don't understand"

With a protocol:
  Client: {"jsonrpc":"2.0","method":"session/prompt","params":{"prompt":"do the thing"}}
  Runtime: "Got it. JSON-RPC, session/prompt method. I know exactly what to do."
```

## 5.2 JSON-RPC — The Foundation

**RPC** = Remote Procedure Call (call a function on another machine as if it were local)
**JSON** = the message format

Every JSON-RPC message has the same structure:

```json
// Request
{"jsonrpc": "2.0", "id": 1, "method": "tools/call", "params": {"name": "grep", "arguments": {"pattern": "TODO"}}}

// Success response
{"jsonrpc": "2.0", "id": 1, "result": {"content": [{"type": "text", "text": "Found 5 TODOs"}]}}

// Error response
{"jsonrpc": "2.0", "id": 1, "error": {"code": -32601, "message": "Unknown method"}}
```

| Field | Purpose |
|-------|---------|
| `jsonrpc` | Always "2.0" — version identifier |
| `id` | Matches request to response (like a ticket number) |
| `method` | What function to call |
| `params` | Arguments for the function |
| `result` | Success data |
| `error` | Failure data |

**The `id` is key** — when multiple requests are in flight, it's how you match responses to requests.

## 5.3 JSON-RPC vs Regular HTTP

```
Regular HTTP:
  POST /api/tools/grep              ← URL decides what to do
  Body: {"pattern": "TODO"}         ← could be any format
  Response: "Found 5 TODOs"         ← could be text, JSON, HTML

JSON-RPC:
  POST / (or stdin)                 ← single endpoint
  Body: {"method": "tools/call",    ← method field decides what to do
         "params": {...}}           ← always structured JSON
  Response: {"result": {...}}       ← always structured JSON
```

| | HTTP REST | JSON-RPC |
|---|---|---|
| What to call | URL path | `method` field |
| Input | Varies | Always JSON `params` |
| Output | Varies | Always JSON `result` or `error` |
| Transport | HTTP only | Anything (HTTP, stdio, WebSocket) |

## 5.4 ACP — Agent Client Protocol

ACP is a higher-level protocol built ON TOP of JSON-RPC. It standardizes how clients talk to AI agents.

```
┌──────────┐   ACP (JSON-RPC over stdio)   ┌──────────────┐
│  Client  │ ─────────────────────────────▶ │  Kiro Agent  │
│  (TUI)   │ ◀───────────────────────────── │  (ACP mode)  │
└──────────┘                                └──────────────┘
```

ACP defines specific methods:

| Method | What it does |
|--------|-------------|
| `initialize` | Handshake — exchange capabilities |
| `session/new` | Create a new chat session |
| `session/load` | Load an existing session |
| `session/prompt` | Send a message to the agent |
| `session/cancel` | Cancel current operation |
| `session/set_mode` | Switch agent config |
| `session/set_model` | Change the model |

And notification types the agent sends back:

| Notification | What it means |
|-------------|--------------|
| `AgentMessageChunk` | Streaming text from the agent |
| `ToolCall` | Agent is calling a tool |
| `ToolCallUpdate` | Tool execution progress |
| `TurnEnd` | Agent finished responding |

## 5.5 MCP — Model Context Protocol

---

### Try This Now

Run this command in your terminal to see MCP in action — a real JSON-RPC exchange with the demo MCP server:

```bash
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' | python3 hands-on/mcp-server/server.py
```

Expected output: a JSON response with `protocolVersion` and `serverInfo`. That is the MCP handshake.

Now list the tools:
```bash
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | python3 hands-on/mcp-server/server.py
```

Expected output: a JSON response listing `get_system_info` and `word_count` with their descriptions and parameter schemas.

You just spoke MCP. Three messages — initialize, tools/list, tools/call — and you have a working tool server. That is the entire protocol.

---

MCP is the protocol between the runtime and tool servers:

```
┌──────────┐   MCP (JSON-RPC)   ┌──────────────┐
│   Kiro   │ ─────────────────▶ │  MCP Server  │
│ Runtime  │ ◀───────────────── │  (your tools)│
└──────────┘                    └──────────────┘
```

MCP has just three key methods:

| Method | What it does |
|--------|-------------|
| `initialize` | Handshake |
| `tools/list` | "What tools do you have?" |
| `tools/call` | "Run this tool with these params" |

## 5.6 How All Protocols Connect

```
┌────────┐  ACP    ┌─────────┐  HTTP/API  ┌─────────┐
│ Client │ ──────▶ │  Kiro   │ ─────────▶ │  Model  │
│ (TUI)  │ ◀────── │ Runtime │ ◀───────── │(Claude) │
└────────┘         └────┬────┘            └─────────┘
                        │
                   MCP  │  MCP
              ┌─────────┼─────────┐
              ▼         ▼         ▼
         ┌────────┐ ┌────────┐ ┌────────┐
         │  Git   │ │ GitHub │ │  Your  │
         │ Server │ │ Server │ │ Server │
         └────────┘ └────────┘ └────────┘

ACP  = Client ↔ Runtime (session management)
MCP  = Runtime ↔ Tool servers (tool execution)
HTTP = Runtime ↔ Model API (inference)
```

## 5.7 Transport: stdio vs HTTP

Both ACP and MCP can use different transports:

```
stdio (local):
  Process A  ──stdin──▶  Process B
  Process A  ◀─stdout──  Process B
  Fast. No network. Used for local MCP servers.

HTTP (remote):
  Client  ──POST──▶  https://server.com/
  Client  ◀─200───  https://server.com/
  Works over network. Used for remote MCP servers and model APIs.
```

---

## Exercise 5.1: Parse the Message

What does this JSON-RPC message do?

```json
{"jsonrpc": "2.0", "id": 42, "method": "tools/call", "params": {"name": "get_system_info", "arguments": {}}}
```

1. What protocol is this? (ACP or MCP?)
2. What is being requested?
3. What would a success response look like?
4. What would an error response look like?

<details>
<summary>Answer</summary>

1. **MCP** — `tools/call` is an MCP method
2. Calling the `get_system_info` tool with no arguments
3. `{"jsonrpc": "2.0", "id": 42, "result": {"content": [{"type": "text", "text": "OS: macOS..."}]}}`
4. `{"jsonrpc": "2.0", "id": 42, "error": {"code": -32601, "message": "Unknown tool"}}`

Note: `id: 42` in the response matches the request — that's how you know which request this response is for.

</details>

---

## Exercise 5.2: Test It Live

Run these commands and observe the JSON-RPC exchange:

```bash
# MCP: List tools
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | python3 hands-on/mcp-server/server.py

# MCP: Call a tool
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"get_system_info","arguments":{}}}' | python3 hands-on/mcp-server/server.py

# MCP: Call with wrong method
echo '{"jsonrpc":"2.0","id":3,"method":"tools/delete","params":{}}' | python3 hands-on/mcp-server/server.py
```

---

## Exercise 5.3: Design a Protocol Exchange

Write the JSON-RPC messages for this scenario:
1. Client creates a new session
2. Client sends "hello"
3. Agent responds with text

<details>
<summary>Answer</summary>

```json
// 1. Client → Agent: create session
{"jsonrpc": "2.0", "id": 1, "method": "session/new", "params": {}}

// Agent → Client: session created
{"jsonrpc": "2.0", "id": 1, "result": {"sessionId": "abc-123"}}

// 2. Client → Agent: send prompt
{"jsonrpc": "2.0", "id": 2, "method": "session/prompt", "params": {"prompt": "hello"}}

// 3. Agent → Client: streaming response (notifications)
{"jsonrpc": "2.0", "method": "session/notification", "params": {"type": "AgentMessageChunk", "content": "Hello! How can I help?"}}
{"jsonrpc": "2.0", "method": "session/notification", "params": {"type": "TurnEnd"}}
```

</details>

---

## Expected Outcomes

After completing this module and its exercises, you should be able to:
- Explain what JSON-RPC is and what the `id`, `method`, `params`, `result`, and `error` fields do
- Distinguish between ACP (client-to-agent) and MCP (agent-to-tools)
- Send a valid JSON-RPC message to an MCP server and interpret the response
- Describe the difference between stdio and HTTP transport

---

## Check Your Understanding

1. What does RPC stand for?
2. What's the `id` field for in JSON-RPC?
3. What's the difference between ACP and MCP?
4. What are the three key MCP methods?
5. What's the difference between stdio and HTTP transport?

---

## Next → [Module 6: Sessions & Memory](../module-06/README.md)
