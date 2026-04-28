# Module 3: Tools — Giving AI Hands

> **Key Question:** How does an agent interact with the real world?

---

## 3.1 What is a Tool?

A tool is a **function the AI can call** to do something in the real world.

Without tools, the AI can only generate text. With tools, it can read files, run commands, search the web, call APIs — anything you expose to it.

```
Without tools:                    With tools:
  You: "Read my config"            You: "Read my config"
  AI: "I can't read files."        AI: [calls read("config.yaml")]
                                   AI: "Your config has 3 sections..."
```

## 3.2 Anatomy of a Tool

Every tool has three parts:

```json
{
  "name": "word_count",                              ← 1. Name (how AI refers to it)
  "description": "Count words, lines, chars in text", ← 2. Description (how AI decides to use it)
  "inputSchema": {                                    ← 3. Parameters (what AI needs to provide)
    "type": "object",
    "properties": {
      "text": {"type": "string", "description": "Text to analyze"}
    },
    "required": ["text"]
  }
}
```

The **description is critical** — it's literally how the AI decides whether to use this tool. A bad description = AI never picks it or picks it at the wrong time.

## 3.3 Built-in Tools (Kiro)

| Tool | What it does | Example |
|------|-------------|---------|
| `read` | Read files | Read README.md |
| `write` | Write/edit files | Create a new file |
| `shell` | Run shell commands | `npm test` |
| `grep` | Search text in files | Find "TODO" in src/ |
| `glob` | Find files by pattern | Find all *.py files |
| `code` | Code intelligence (AST) | Find function definitions |
| `use_aws` | AWS API calls | List S3 buckets |
| `web_search` | Search the web | Look up documentation |
| `web_fetch` | Fetch URL content | Read a webpage |
| `knowledge` | Persistent search | Search indexed docs |
| `todo_list` | Track tasks | Create/complete tasks |
| `subagent` | Spawn other agents | Parallel research |

---

### Try This Now

Run each of these in Kiro and watch which tool gets called:

```
Find all .md files in this directory
```
Expected: you will see `glob` called with a pattern like `**/*.md`.

```
Search for the word "TODO" in all files
```
Expected: you will see `grep` called with pattern `TODO`.

```
What operating system am I running?
```
Expected: you will see `shell` called with a command like `uname -a`.

Each request triggers a different tool. The agent picks the tool based on your intent and the tool descriptions it was given. That matching process is covered in Module 4.

---

## 3.4 Tool vs Subagent

This confuses people. A subagent IS a tool — but a special one:

```
Regular tool:
  Agent → grep("TODO") → results → done
  One call. One result. Simple.

Subagent tool:
  Agent → subagent({stages: [...]})
            ├── spawns Agent A (own session, own tools)
            ├── spawns Agent B (own session, own tools)
            └── collects results from both
  Creates new agents. They have their own tools. Complex.
```

| | Regular Tool | Subagent |
|---|---|---|
| Who does the work? | The tool itself | Other agents |
| Has its own session? | No | Yes |
| Can use tools? | No — it IS a tool | Yes — spawned agents have tools |
| Parallelism? | No | Yes |

**Analogy:** A screwdriver (regular tool) vs hiring contractors (subagent). Both are "tools" in your toolbox, but one creates workers.

## 3.5 Custom Tools via MCP

You can't add built-in tools, but you can create custom tools via **MCP servers** (Model Context Protocol).

An MCP server is a small program that:
1. Speaks JSON-RPC
2. Exposes tools with names, descriptions, and parameter schemas
3. Connects to Kiro via stdio (local) or HTTP (remote)

```
┌──────────┐    JSON-RPC     ┌──────────────────┐
│   Kiro   │ ──────────────▶ │  Your MCP Server │
│  Agent   │ ◀────────────── │  (Python/Node/Go)│
└──────────┘                 └──────────────────┘
```

Example — a custom MCP server in Python that exposes a `word_count` tool:

```python
# When Kiro sends: {"method": "tools/list"}
# Server responds with tool definitions

# When Kiro sends: {"method": "tools/call", "params": {"name": "word_count", "arguments": {"text": "hello"}}}
# Server responds with: {"result": {"content": [{"type": "text", "text": "Words: 1"}]}}
```

See `hands-on/mcp-server/server.py` for a complete working example.

## 3.6 Tool Permissions

Not all tools should run freely. Kiro has a permission system:

```json
{
  "tools": ["read", "write", "shell"],
  "allowedTools": ["read"],
  "toolsSettings": {
    "write": {
      "allowedPaths": ["src/**"],
      "deniedPaths": ["node_modules/**"]
    },
    "shell": {
      "allowedCommands": ["npm test", "npm run build"]
    }
  }
}
```

| Setting | What it does |
|---------|-------------|
| `tools` | Which tools are available at all |
| `allowedTools` | Which tools run without asking you |
| `toolsSettings` | Fine-grained restrictions per tool |

Tools NOT in `allowedTools` will prompt you: "Allow write to src/app.js? [y/n]"

## 3.7 Hooks — Intercepting Tool Calls

Hooks let you run custom scripts before/after tool execution:

```
preToolUse hook:
  Agent wants to call write("production.env")
       │
       ▼
  Your hook script runs → checks the path
       │
  exit 0 → allow it
  exit 2 → BLOCK it (returns error to AI)
```

```json
{
  "hooks": {
    "preToolUse": [
      {"matcher": "write", "command": "~/.kiro/hooks/validate-write.sh"}
    ]
  }
}
```

This is how you add safety rails without modifying the agent or model.

---

### Try This Now — Build and Test a Hook

**Step 1: Create a logging hook**

Create `hands-on/hooks/pre-tool-log.sh`:

```bash
#!/bin/bash
# Logs every tool call to a file. Exit 0 = allow.
LOG_FILE="/tmp/kiro-hook-log.txt"
INPUT=$(cat)
echo "[$(date '+%H:%M:%S')] RAW: $INPUT" >> "$LOG_FILE"
TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_name', 'unknown'))
" 2>/dev/null)
echo "[$(date '+%H:%M:%S')] Tool: $TOOL_NAME" >> "$LOG_FILE"
exit 0
```

```bash
chmod +x hands-on/hooks/pre-tool-log.sh
```

**Step 2: Create a blocking hook**

Create `hands-on/hooks/block-rm.sh`:

```bash
#!/bin/bash
# Blocks shell commands containing "rm". Exit 2 = block.
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)
if echo "$COMMAND" | grep -q "rm "; then
    echo "BLOCKED: refusing to run 'rm'" >&2
    exit 2
fi
exit 0
```

```bash
chmod +x hands-on/hooks/block-rm.sh
```

**Step 3: Add hooks to your agent config**

In your agent JSON (`~/.kiro/agents/demo-agent.json`), add:

```json
"hooks": {
  "preToolUse": [
    { "command": "/full/path/to/hands-on/hooks/pre-tool-log.sh" },
    { "matcher": "shell", "command": "/full/path/to/hands-on/hooks/block-rm.sh" }
  ]
}
```

**Step 4: Test**

Reload the agent (`/agent kiro_default` then `/agent demo-agent`), then:

```
What files are in the current directory?
```

Check the log:
```bash
cat /tmp/kiro-hook-log.txt
```

You'll see the hook received JSON with `tool_name`, `tool_input`, `session_id`, and `cwd`.

Now test the blocker:
```
Create a file /tmp/hook-test.txt with "hello", then delete it
```

The agent will create the file successfully, but when it tries `rm`, the hook blocks it (exit 2). The agent reports the failure and explains why.

**What you learned:**
- Hooks receive JSON via stdin: `{"hook_event_name": "preToolUse", "tool_name": "...", "tool_input": {...}}`
- `exit 0` = allow the tool call
- `exit 2` = block it (agent sees an error and adapts)
- `matcher` limits which tools trigger the hook

---

## 3.8 Safety and Guardrails

Agents execute real commands on your system. A misconfigured agent can delete files, overwrite code, or run destructive commands. Safety is not optional — it's part of the design.

### Why this matters

A chatbot that gives bad advice is annoying. An agent that runs bad advice is dangerous. When you give an agent tools like `shell` and `write`, you're giving it the ability to change your system. The agent will do what it thinks you asked — even if that's not what you meant.

### The three layers of safety

```
Layer 1: Tool restrictions (what the agent CAN do)
  └── tools, allowedTools, toolsSettings

Layer 2: Confirmation prompts (what the agent MUST ask about)
  └── Tools not in allowedTools require your approval

Layer 3: Hooks (what gets checked automatically)
  └── preToolUse hooks can block dangerous operations
```

### Practical guidelines

| Guideline | Why |
|-----------|-----|
| Start with read-only tools | Add `write` and `shell` only when needed |
| Use `allowedTools` narrowly | Auto-approve reads, require confirmation for writes |
| Restrict paths | Use `allowedPaths`/`deniedPaths` to protect sensitive files |
| Restrict commands | Use `allowedCommands` to limit what `shell` can run |
| Review before approving | When the agent asks "Allow?", read what it wants to do |
| Test in a safe directory | Don't point a new agent at your production code first |

### Example: A safe default config

```json
{
  "tools": ["read", "write", "shell", "grep", "glob"],
  "allowedTools": ["read", "grep", "glob"],
  "toolsSettings": {
    "write": {
      "deniedPaths": [".env", "*.key", "*.pem", "node_modules/**"]
    },
    "shell": {
      "allowedCommands": ["npm test", "npm run build", "python -m pytest"]
    }
  }
}
```

This config lets the agent read freely, but requires your approval for writes and only allows specific shell commands.

### Key takeaway

Tools give agents power. Permissions, confirmation prompts, and hooks give you control. Always configure both.

## 3.9 Skills and Powers — Packaging Knowledge

Beyond individual tools, Kiro supports two higher-level packaging systems: **Skills** and **Powers**.

### Skills — Portable instruction packages

A skill is a folder with a `SKILL.md` file that bundles instructions, scripts, and templates into a reusable package. Skills follow the open [Agent Skills](https://agentskills.io) standard.

```
my-skill/
├── SKILL.md           ← Required (name + description + instructions)
├── scripts/           ← Optional executable code
├── references/        ← Optional documentation
└── assets/            ← Optional templates
```

Example `SKILL.md`:
```markdown
---
name: pr-review
description: Review pull requests for code quality, security issues, and test coverage.
---

## Review process
1. Check for security vulnerabilities
2. Verify error handling
3. Confirm test coverage
```

**How skills activate:** Kiro loads only the name and description at startup. When your request matches a skill's description, Kiro loads the full instructions. This keeps context small until needed.

**Scope:**
- Workspace skills: `.kiro/skills/` — project-specific
- Global skills: `~/.kiro/skills/` — available everywhere

### Powers — Tools + knowledge bundled together

A power bundles an MCP server (tools) with a `POWER.md` (guidance on when and how to use those tools). Powers activate dynamically based on keywords in your conversation.

```
Power = MCP tools + POWER.md steering + optional hooks
```

**The problem powers solve:** Connect 5 MCP servers and you load 100+ tool definitions upfront — eating 50K+ tokens before your first prompt. Powers load tools on-demand instead.

**How powers activate:**
1. You mention "payment" → Stripe power activates (loads Stripe MCP tools + guidance)
2. You switch to database work → Supabase power activates, Stripe deactivates
3. Only relevant tools are in context at any time

### Skills vs Powers vs Tools

| | Tools | Skills | Powers |
|---|---|---|---|
| What | Individual functions | Instruction packages | Tools + knowledge bundled |
| Contains | Name + description + schema | SKILL.md + scripts | POWER.md + MCP server config |
| Activation | Always loaded | On-demand (description match) | Dynamic (keyword match) |
| Use case | Read files, run commands | Workflows (deploy, review) | Integrations (Stripe, Datadog) |

**When to use what:**
- Need a single function? → **Tool** (MCP server)
- Need a reusable workflow with instructions? → **Skill**
- Need tools + guidance that activate together? → **Power**

---

## Exercise 3.1: Match the Tool

What tool would the AI use for each request?

| Request | Tool |
|---------|------|
| "Read my package.json" | ? |
| "Find all files named *.test.js" | ? |
| "Search for 'deprecated' in the codebase" | ? |
| "Run the test suite" | ? |
| "Compare React vs Vue vs Svelte" | ? |
| "List my S3 buckets" | ? |

<details>
<summary>Answer</summary>

| Request | Tool |
|---------|------|
| "Read my package.json" | `read` |
| "Find all files named *.test.js" | `glob` |
| "Search for 'deprecated' in the codebase" | `grep` |
| "Run the test suite" | `shell` (npm test) |
| "Compare React vs Vue vs Svelte" | `subagent` (parallel research) |
| "List my S3 buckets" | `use_aws` |

</details>

---

## Exercise 3.2: Test the MCP Server

Run this in your terminal:

```bash
# List available tools
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' | python3 hands-on/mcp-server/server.py

# Call a tool
echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"word_count","arguments":{"text":"hello world foo bar"}}}' | python3 hands-on/mcp-server/server.py
```

Questions:
1. How many tools does the server expose?
2. What's the word count result?
3. What happens if you call a tool that doesn't exist?

<details>
<summary>Answer</summary>

1. Two tools: `get_system_info` and `word_count`
2. Words: 4, Lines: 1, Chars: 19
3. You get a JSON-RPC error: `{"error": {"code": -32601, "message": "Unknown tool: ..."}}`

</details>

---

## Exercise 3.3: Design a Tool

Design a tool definition (just the JSON schema) for a tool that:
- Converts temperatures between Celsius and Fahrenheit
- Takes a number and a direction ("c_to_f" or "f_to_c")

<details>
<summary>Answer</summary>

```json
{
  "name": "convert_temperature",
  "description": "Convert temperature between Celsius and Fahrenheit",
  "inputSchema": {
    "type": "object",
    "properties": {
      "value": {"type": "number", "description": "Temperature value to convert"},
      "direction": {
        "type": "string",
        "enum": ["c_to_f", "f_to_c"],
        "description": "Conversion direction"
      }
    },
    "required": ["value", "direction"]
  }
}
```

The description is key — it tells the AI WHEN to use this tool. If someone says "what's 100°C in Fahrenheit?", the AI matches that intent to this description.

</details>

---

## Expected Outcomes

After completing this module and its exercises, you should be able to:
- Name the three parts of a tool definition (name, description, input schema)
- Match a user request to the correct tool
- Explain the difference between a regular tool and the subagent tool
- Describe how custom tools are added via MCP servers
- Design a tool definition (JSON schema) for a new capability

---

## Check Your Understanding

1. What are the three parts of a tool definition?
2. Why is the tool description so important?
3. How is a subagent different from a regular tool?
4. How do you add custom tools to Kiro?
5. What does `allowedTools` do vs `tools`?

---

## Next → [Module 4: How AI Decides What To Do](../module-04/README.md)
