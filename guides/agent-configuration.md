# Agent Configuration Guide

An agent is a JSON file that defines an AI personality — what it knows, what tools it can use, and how it behaves.

---

## Minimal Agent

The simplest possible agent:

```json
{
  "name": "simple",
  "description": "A minimal agent",
  "prompt": "You are a helpful assistant."
}
```

That's it. Name, description, prompt. Everything else is optional.

---

## Building Up: Layer by Layer

### Layer 1: Add Tools

```json
{
  "name": "coder",
  "description": "Can read and write code",
  "prompt": "You are a coding assistant.",
  "tools": ["fs_read", "fs_write", "execute_bash", "grep", "glob", "code"]
}
```

Common tools:
| Tool | What it does |
|------|-------------|
| `fs_read` | Read files |
| `fs_write` | Write/edit files |
| `execute_bash` | Run shell commands |
| `grep` | Search text in files |
| `glob` | Find files by pattern |
| `code` | Code intelligence (AST search, symbols) |
| `use_aws` | Make AWS API calls |
| `knowledge` | Index and search content |
| `web_search` | Search the web |
| `web_fetch` | Fetch URL content |
| `subagent` | Spawn multi-agent pipelines |

### Layer 2: Auto-Approve Safe Tools

```json
{
  "name": "coder",
  "prompt": "You are a coding assistant.",
  "tools": ["fs_read", "fs_write", "execute_bash", "grep"],
  "allowedTools": ["fs_read", "grep", "glob"]
}
```

`allowedTools` = tools that run WITHOUT asking you "Allow?" each time.

Supports wildcards:
```json
"allowedTools": [
  "fs_*",           // all file tools
  "@git/git_status", // specific MCP tool
  "@fetch"           // all tools from fetch server
]
```

### Layer 3: Restrict Tool Behavior

```json
{
  "name": "safe-coder",
  "prompt": "You are a careful coding assistant.",
  "tools": ["fs_read", "fs_write", "execute_bash"],
  "toolsSettings": {
    "fs_write": {
      "allowedPaths": ["src/**", "tests/**"],
      "deniedPaths": ["node_modules/**", ".env"]
    },
    "execute_bash": {
      "allowedCommands": ["npm test", "npm run build"],
      "autoAllowReadonly": true
    }
  }
}
```

This agent can ONLY write to `src/` and `tests/`, and can ONLY run `npm test` and `npm run build`.

### Layer 4: Add Context Files

```json
{
  "name": "project-helper",
  "prompt": "You help with this specific project.",
  "tools": ["fs_read", "fs_write", "code"],
  "resources": [
    "file://README.md",
    "file://src/**/*.ts",
    "file://package.json",
    "skill://.kiro/skills/**/SKILL.md"
  ]
}
```

`resources` = files loaded into the agent's context automatically.
- `file://` — always loaded
- `skill://` — loaded on demand (needs YAML frontmatter with name + description)

### Layer 5: Add Hooks (Lifecycle Scripts)

```json
{
  "name": "guarded-coder",
  "prompt": "You are a careful developer.",
  "tools": ["fs_read", "fs_write", "execute_bash"],
  "hooks": {
    "agentSpawn": [
      { "command": "git status" }
    ],
    "preToolUse": [
      { "matcher": "fs_write", "command": "echo 'Writing file...'" }
    ],
    "postToolUse": [
      { "matcher": "execute_bash", "command": "echo 'Command ran'" }
    ],
    "stop": [
      { "command": "npm run lint" }
    ]
  }
}
```

Hook triggers:
```
agentSpawn        → agent starts up
userPromptSubmit  → you send a message
preToolUse        → BEFORE a tool runs (exit 2 = block it!)
postToolUse       → AFTER a tool runs
stop              → agent finishes responding
```

### Layer 6: Add MCP Servers (External Tools)

```json
{
  "name": "full-stack",
  "prompt": "Full-stack dev with git and GitHub.",
  "tools": ["fs_read", "fs_write", "execute_bash"],
  "mcpServers": {
    "git": {
      "command": "mcp-server-git",
      "args": ["--stdio"]
    },
    "github": {
      "command": "mcp-server-github",
      "args": ["--stdio"],
      "env": { "GITHUB_TOKEN": "$GITHUB_TOKEN" }
    }
  }
}
```

MCP servers add external tools. Remote servers also supported:
```json
"mcpServers": {
  "remote-api": {
    "url": "https://mcp.example.com/sse",
    "headers": { "Authorization": "Bearer $API_TOKEN" }
  }
}
```

### Layer 7: Keyboard Shortcut & Welcome Message

```json
{
  "name": "rust-dev",
  "prompt": "Rust expert.",
  "keyboardShortcut": "ctrl+shift+r",
  "welcomeMessage": "Ready to help with Rust! What are we building?"
}
```

Press `Ctrl+Shift+R` to instantly switch to this agent. Press again to switch back.

---

## Complete Real-World Example

```json
{
  "name": "rust-dev",
  "description": "Rust development agent with full toolset",
  "prompt": "You are an expert Rust developer. Focus on safety, performance, and idiomatic code.",
  "model": "<model-id>",
  "tools": ["fs_read", "fs_write", "execute_bash", "grep", "glob", "code"],
  "allowedTools": ["fs_read", "grep", "glob"],
  "toolsSettings": {
    "fs_write": {
      "allowedPaths": ["src/**", "tests/**"],
      "deniedPaths": ["target/**"]
    },
    "execute_bash": {
      "allowedCommands": ["cargo check", "cargo test", "cargo build"],
      "autoAllowReadonly": true
    }
  },
  "resources": ["file://src/**/*.rs", "file://Cargo.toml"],
  "hooks": {
    "agentSpawn": [{ "command": "cargo --version && rustc --version" }],
    "stop": [{ "command": "cargo check 2>&1 | tail -5" }]
  },
  "mcpServers": {
    "git": { "command": "mcp-server-git", "args": ["--stdio"] }
  },
  "keyboardShortcut": "ctrl+shift+r",
  "welcomeMessage": "Ready to help with Rust development!"
}
```

---

## Where Agent Files Live

| Location | Path | Priority |
|----------|------|----------|
| Local (per-project) | `.kiro/agents/<name>.json` | Higher (wins) |
| Global (user-wide) | `~/.kiro/agents/<name>.json` | Lower |

---

## Built-in Agents (cannot be edited)

| Name | Role |
|------|------|
| `kiro_default` | General-purpose assistant |
| `kiro_planner` | Breaks ideas into plans |
| `kiro_guide` | Answers questions about Kiro |

---

## Quick Commands

```
/agent                          → list all agents
/agent <name>                   → switch to agent
/agent create my-agent          → create new agent
/agent create my-agent --from kiro_default  → clone from existing
/agent create my-agent --directory .kiro/agents  → create locally
/agent edit my-agent            → edit agent config
```
