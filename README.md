# Kiro Concepts Demo 🧠

Learn how Kiro orchestrates AI agents using ACP, DAGs, Subagents, and Session Management.

## Table of Contents
1. [ACP — Agent Client Protocol](#1-acp--agent-client-protocol)
2. [DAG — Directed Acyclic Graph](#2-dag--directed-acyclic-graph)
3. [Subagent — Multi-Agent Pipelines](#3-subagent--multi-agent-pipelines)
4. [Session Management — Agent Coordination](#4-session-management--agent-coordination)

---

## 1. ACP — Agent Client Protocol

**What:** An open protocol (like HTTP for web, but for AI agents) that standardizes how clients talk to AI agents.

**How it works:**
```
┌──────────┐   JSON-RPC (stdin)    ┌──────────────┐
│  Client  │ ───────────────────▶  │  Kiro Agent  │
│  (TUI)   │ ◀───────────────────  │  (ACP mode)  │
└──────────┘   JSON-RPC (stdout)   └──────────────┘
```

**Key methods:**
| Method | What it does |
|--------|-------------|
| `initialize` | Handshake — exchange capabilities |
| `session/new` | Create a new chat session |
| `session/prompt` | Send a message to the agent |
| `session/cancel` | Cancel current operation |

**Start ACP mode:**
```bash
kiro-cli acp
# Now it reads JSON-RPC from stdin, writes to stdout
```

**Real-world analogy:** ACP is like a waiter taking your order (client request) to the kitchen (agent) and bringing back food (response). The protocol defines the menu format.

---

## 2. DAG — Directed Acyclic Graph

**What:** A way to define task dependencies — which tasks can run in parallel and which must wait.

**Rules:**
- **Directed** → tasks flow in one direction (A → B, never B → A)
- **Acyclic** → no loops (A → B → C → A is forbidden)
- **Graph** → tasks are nodes, dependencies are edges

**Visual:**
```
        ┌───────────────────────────────────┐
        │         NO dependencies?          │
        │         → Run in PARALLEL         │
        └───────────────────────────────────┘

Example: Research Jest AND Research Vitest simultaneously

        ┌──────────┐       ┌──────────────┐
        │  Jest    │       │   Vitest     │
        │ Research │       │  Research    │
        └────┬─────┘       └──────┬───────┘
             │                    │
             └────────┬───────────┘
                      ▼
              ┌──────────────┐
              │  Compare &   │    ← depends_on: [jest, vitest]
              │  Recommend   │
              └──────────────┘
```

**Invalid DAG (cycle):**
```
    A → B → C → A   ❌  This loops forever!
```

See `diagrams/dag-examples.md` for more visual examples.

---

## 3. Subagent — Multi-Agent Pipelines

**What:** A tool that spawns multiple AI agents as a pipeline. Each stage is a separate session running a specialized task.

**How to think about it:**
```
You (main agent)
 ├── spawns → Stage 1 (researcher)     ─┐
 ├── spawns → Stage 2 (researcher)     ─┤── parallel
 └── waits for both, then:              ─┘
     spawns → Stage 3 (implementer)    ← sequential
```

**Real example you can ask Kiro:**
```
"Compare React vs Vue vs Svelte for my project"
```

Kiro internally does:
```json
{
  "task": "Compare frontend frameworks",
  "stages": [
    {"name": "react-research", "role": "kiro_default", "prompt_template": "Research React for {task}"},
    {"name": "vue-research", "role": "kiro_default", "prompt_template": "Research Vue for {task}"},
    {"name": "svelte-research", "role": "kiro_default", "prompt_template": "Research Svelte for {task}"},
    {"name": "comparison", "role": "kiro_default", "prompt_template": "Compare findings for {task}",
     "depends_on": ["react-research", "vue-research", "svelte-research"]}
  ]
}
```

**Three patterns:**

| Pattern | Shape | Use case |
|---------|-------|----------|
| Parallel | `═══` | Independent research |
| Sequential | `→→→` | Research → Implement → Review |
| Fan-out/Fan-in | `<>` | Parallel work → single summary |

See `examples/` for runnable pipeline configs.

---

## 4. Session Management — Agent Coordination

**What:** The internal messaging system agents use to talk to each other.

**Think of it like a team chat:**
```
┌─────────────────────────────────────────────┐
│  Session: "auth-reviewer"                    │
│  Status: active                              │
│  Inbox: 2 messages                           │
│  Group: review-team                          │
├─────────────────────────────────────────────┤
│  Session: "perf-analyzer"                    │
│  Status: idle                                │
│  Inbox: 0 messages                           │
│  Group: review-team                          │
└─────────────────────────────────────────────┘
```

**Available commands:**

| Command | What it does | Analogy |
|---------|-------------|---------|
| `spawn_session` | Create a new agent session | Hiring a new team member |
| `send_message` | Send msg to another session | Slack DM |
| `read_messages` | Check your inbox | Reading notifications |
| `list_sessions` | See all sessions | Team roster |
| `manage_group` | Group sessions together | Creating a Slack channel |
| `broadcast` | Message all in a group | @channel message |
| `interrupt` | Redirect a session's task | "Drop that, do this instead" |
| `inject_context` | Silently add info to session | Sharing a doc without pinging |
| `revive_session` | Restart a terminated session | Re-hiring someone |

See `cheatsheets/session-commands.md` for the full reference.

---

## How They All Connect

```
┌─────────────────────────────────────────────────────────┐
│                    YOU (User)                             │
└────────────────────────┬────────────────────────────────┘
                         │ (types a request)
                         ▼
┌─────────────────────────────────────────────────────────┐
│              ACP Layer (JSON-RPC protocol)                │
│         Handles: session/new, session/prompt, etc.       │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│              Main Agent (your chat session)               │
│         Decides: "I need multiple agents for this"       │
└────────────────────────┬────────────────────────────────┘
                         │ uses subagent tool
                         ▼
┌─────────────────────────────────────────────────────────┐
│              DAG Scheduler                                │
│         Resolves dependencies, decides execution order   │
└──────────┬─────────────┼─────────────┬──────────────────┘
           │             │             │
           ▼             ▼             ▼
┌────────────┐  ┌────────────┐  ┌────────────┐
│ Session A  │  │ Session B  │  │ Session C  │  ← parallel
│ (research) │  │ (research) │  │ (waits...) │
└─────┬──────┘  └─────┬──────┘  └────────────┘
      │                │                ▲
      │  summary()     │  summary()     │ depends_on A,B
      └────────────────┴────────────────┘
                       │
                       ▼
              Session C starts → summary() → Main Agent → You
```

---

## 5. Kiro Slash Commands — Quick Reference

Kiro has a rich set of `/` commands you can type directly in the chat. Here are the most useful ones:

### Session & Conversation
| Command | What it does |
|---------|-------------|
| `/chat save <name>` | Save current conversation to a file |
| `/chat load <name>` | Load a previously saved conversation |
| `/chat new` | Start a fresh conversation |
| `/clear` | Clear conversation history |
| `/compact` | Summarize old turns to free up context space |
| `/transcript` | View full conversation in your pager |

### Agents & Models
| Command | What it does |
|---------|-------------|
| `/agent` | List all agents |
| `/agent <name>` | Switch to a specific agent |
| `/agent create <name>` | Create a new agent |
| `/plan <idea>` | Switch to planner agent with a task |
| `/guide <question>` | Ask the guide agent about Kiro itself |
| `/model` | List models or switch to a different one |

### Context & Knowledge
| Command | What it does |
|---------|-------------|
| `/context add <path>` | Add files to the agent's context |
| `/context clear` | Remove all context files |
| `/knowledge add <name> <path>` | Index files for persistent semantic search |
| `/knowledge show` | List all knowledge base entries |

### Tools & MCP
| Command | What it does |
|---------|-------------|
| `/tools` | Show available tools and trust status |
| `/tools trust-all` | Auto-approve all tools (no more prompts) |
| `/tools trust <name>` | Trust a specific tool |
| `/mcp` | Show connected MCP servers |
| `/hooks` | View configured lifecycle hooks |

### Productivity
| Command | What it does |
|---------|-------------|
| `/spawn <task>` | Run a task in a background agent session |
| `/editor` | Open `$EDITOR` to write a multi-line prompt |
| `/paste` | Paste an image from clipboard |
| `/copy` | Copy last response to clipboard |
| `/code overview` | Get a high-level codebase structure |

### Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| `Ctrl+G` | Crew monitor — see all active sessions |
| `Ctrl+X` | Activity tray — task progress + message queue |
| `Ctrl+R` | Search command history |
| `Ctrl+O` | Toggle tool output visibility |
| `Esc` | Dismiss overlay panels |

> Full reference: `cheatsheets/kiro-commands.md`

---

## Try It Yourself

### 1. Spawn a parallel session
```
/spawn Research the best practices for error handling in Rust
```
Then press `Ctrl+G` to watch it run.

### 2. Ask something that triggers subagents
```
Compare the pros and cons of PostgreSQL vs MySQL vs SQLite for a small web app
```
Kiro may use subagents to research each in parallel.

### 3. Check your sessions
Press `Ctrl+G` at any time to see the crew monitor showing all active sessions.

---

## Files in This Demo

```
kiro-concepts-demo/
├── README.md                          ← You are here
├── guides/
│   └── agent-configuration.md         ← Agent config from zero to full (7 layers)
├── diagrams/
│   ├── dag-examples.md                ← Visual DAG patterns
│   └── end-to-end-flow.md            ← Full flow: You → ACP → Agent → Subagents → You
├── examples/
│   ├── 01-parallel-research.json      ← Simple parallel pipeline
│   ├── 02-sequential-pipeline.json    ← Research → Implement → Review
│   └── 03-fan-out-fan-in.json         ← Complex dependency pattern
├── hands-on/                          ← 🔥 PRACTICAL DEMO
│   ├── WALKTHROUGH.md                 ← Step-by-step guide
│   ├── mcp-server/
│   │   └── server.py                 ← Your custom MCP tool (Python)
│   └── agent/
│       └── demo-agent.json           ← Agent config wired to custom tool
└── cheatsheets/
    ├── session-commands.md            ← Session management + slash commands reference
    └── kiro-commands.md               ← Full Kiro slash commands deep-dive
```

## Recommended Reading Order

1. `guides/agent-configuration.md` — Understand what an agent IS
2. `README.md` (sections 1-4) — Learn ACP, DAG, Subagent, Sessions
3. `diagrams/end-to-end-flow.md` — See how everything connects
4. `diagrams/dag-examples.md` — Visual DAG patterns
5. `examples/` — Real pipeline configs
6. `cheatsheets/session-commands.md` — Session management quick reference
7. `cheatsheets/kiro-commands.md` — Full slash commands deep-dive
8. **`hands-on/WALKTHROUGH.md`** — 🔥 Build a custom tool, wire it in, deploy to AWS
