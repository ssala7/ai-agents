# Kiro CLI — Slash Commands Deep Dive

A complete reference for every `/` command in Kiro CLI, with explanations of what each does, when to use it, and real examples.

Type `/` in the chat input to see autocomplete suggestions. Press `Tab` to complete.

---

## Table of Contents

1. [Conversation Management](#1-conversation-management)
2. [Agents](#2-agents)
3. [Models](#3-models)
4. [Tools & MCP](#4-tools--mcp)
5. [Context & Knowledge](#5-context--knowledge)
6. [Code Intelligence](#6-code-intelligence)
7. [Hooks](#7-hooks)
8. [Input & Editing](#8-input--editing)
9. [Spawning Sessions](#9-spawning-sessions)
10. [UI & Display](#10-ui--display)
11. [Info & Feedback](#11-info--feedback)
12. [Keyboard Shortcuts](#12-keyboard-shortcuts)
13. [Quick Decision Guide](#13-quick-decision-guide)

---

## 1. Conversation Management

### /chat save
Save the current conversation to a file so you can resume it later.

```
/chat save <path>           → Save to file
/chat save --force <path>   → Overwrite if file already exists
```

**When to use:** Before closing a long debugging session, before switching tasks, or to archive important conversations.

**Example:**
```
/chat save auth-refactor-session
```
Creates `auth-refactor-session.json` in the current directory.

---

### /chat load
Load a previously saved conversation from a file.

```
/chat load <path>
```

Supports `.json`, `.zip`, and legacy V1 formats. If no extension is given, tries `.zip` then `.json` automatically.

**When to use:** Resume exactly where you left off — the agent gets the full conversation history back.

**Example:**
```
/chat load auth-refactor-session
```

---

### /chat new
Start a completely fresh conversation (new session ID, empty history).

```
/chat new
/chat new <opening prompt>
```

**When to use:** When you want a clean slate without quitting and restarting Kiro.

**Example:**
```
/chat new Let's start working on the payment module
```

---

### /clear
Clears the conversation history from the current session context.

```
/clear
```

**When to use:** When the context window is getting full and the model starts losing focus. Faster than `/compact` — just wipes everything.

**Difference from /compact:** `/clear` deletes history. `/compact` summarizes it and keeps the summary.

---

### /compact
Summarizes old conversation turns to free up context space while preserving continuity.

```
/compact
```

**When to use:** Long sessions where you want to keep going without losing the thread. The model gets a summary of what was discussed instead of the raw history.

**Difference from /clear:** `/compact` keeps a summary. `/clear` removes everything.

---

### /transcript
Opens the full conversation transcript in your `$PAGER` (usually `less`). Quit with `q`.

```
/transcript
```

**When to use:** Review everything said in the session, search through it, or copy specific parts.

---

## 2. Agents

### /agent
List, switch, create, or edit agents.

```
/agent                                          → List all available agents
/agent <name>                                   → Switch to a specific agent
/agent create <name>                            → Create a new agent interactively
/agent create <name> --from kiro_default        → Clone from an existing agent
/agent create <name> --directory .kiro/agents   → Create as a local (project-scoped) agent
/agent edit <name>                              → Open agent's JSON config in your editor
```

**Built-in agents (cannot be edited):**

| Agent | Role | Best for |
|-------|------|----------|
| `kiro_default` | General-purpose assistant | Everything |
| `kiro_planner` | Breaks ideas into implementation plans | Planning features, architecture |
| `kiro_guide` | Answers questions about Kiro CLI | Learning Kiro, troubleshooting |

**Agent file locations:**
- Local (project): `.kiro/agents/<name>.json` — takes priority
- Global (user-wide): `~/.kiro/agents/<name>.json`

**When to use:** Switch to a specialized agent for a specific task. E.g., use `kiro_planner` to design a feature, then switch back to `kiro_default` to implement it.

**Example:**
```
/agent kiro_planner
Plan a microservices migration for a monolithic Node.js app

/agent kiro_default
Now implement the first service: user authentication
```

---

### /plan
Shortcut to switch to the `kiro_planner` agent, optionally with an immediate prompt.

```
/plan
/plan <idea or task>
```

**When to use:** When you have a vague idea and need it broken into concrete steps before writing any code.

**Example:**
```
/plan Add real-time notifications to a React + Node.js app using WebSockets
```

The planner will produce a structured implementation plan with phases, dependencies, and file changes.

---

### /guide
Switch to the `kiro_guide` agent for help with Kiro CLI itself. Running `/guide` again toggles back to your previous agent.

```
/guide
/guide <question>
```

**When to use:** When you're unsure how a Kiro feature works, what a command does, or how to configure something.

**Examples:**
```
/guide How do I save a conversation?
/guide What's the difference between /clear and /compact?
/guide How do hooks work?
/guide How do I create a custom agent?
```

---

## 3. Models

### /model
View available models or switch to a different one mid-session.

```
/model                  → Show all available models + current selection
/model <model-name>     → Switch to a specific model
```

**When to use:**
- Switch to a faster/cheaper model for simple tasks (file listing, quick edits)
- Switch to a more capable model for complex reasoning (architecture decisions, debugging)
- All without restarting the session

**Example:**
```
/model
# pick from the list, or:
/model <model-id>
```

---

## 4. Tools & MCP

### /tools
View all available tools and manage trust settings (which tools can run without asking you first).

```
/tools                  → Show all tools + their current trust status
/tools trust-all        → Auto-approve ALL tools (no more "Allow?" prompts)
/tools trust <name>     → Trust a specific tool
/tools untrust <name>   → Remove trust from a specific tool
/tools reset            → Reset all trust settings back to defaults
```

**Trust levels explained:**
- **Untrusted (default):** Kiro asks "Allow?" before each tool use
- **Trusted:** Tool runs automatically without prompting
- **trust-all:** Everything runs without prompting — use carefully

**When to use:**
- `/tools trust-all` — when you're in a flow and don't want interruptions (e.g., running a long refactor)
- `/tools trust read` — trust read-only tools but keep write/execute prompts
- `/tools reset` — restore safety prompts after a session

**Example:**
```
/tools trust read
/tools trust grep
/tools trust glob
# Now reads are automatic, but writes and bash still ask
```

---

### /mcp
Show all configured MCP (Model Context Protocol) servers and their status.

```
/mcp
```

**When to use:** Verify which external tool servers are connected. If a tool isn't working, check here first to see if the MCP server started correctly.

**MCP servers are configured in agent JSON:**
```json
"mcpServers": {
  "git": { "command": "mcp-server-git", "args": ["--stdio"] },
  "github": { "command": "mcp-server-github", "args": ["--stdio"] }
}
```

---

### /hooks
View all lifecycle hooks configured for the current agent.

```
/hooks
```

**Hook triggers:**

| Trigger | When it fires | Common use |
|---------|--------------|------------|
| `agentSpawn` | Agent starts up | Print versions, check environment |
| `userPromptSubmit` | You send a message | Log prompts, validate input |
| `preToolUse` | Before a tool runs | Block dangerous commands (exit 2) |
| `postToolUse` | After a tool runs | Run tests after file writes |
| `stop` | Agent finishes responding | Auto-lint, auto-format |

**When to use:** Verify what automation is running around your agent's actions. If something unexpected is happening (e.g., tests running after every response), check `/hooks`.

---

## 5. Context & Knowledge

### /context
Manage files loaded into the agent's active context window, or check token usage.

```
/context                        → Show current token usage breakdown
/context add <path>             → Add a file or glob pattern to context
/context add --force <path>     → Add even if already present
/context remove <path>          → Remove a specific file from context
/context clear                  → Remove all manually added context files
```

**When to use:** Manually inject relevant files so the agent has the right information without you pasting it.

**Examples:**
```
/context add src/auth/**/*.ts
/context add docs/api-spec.md
/context add package.json
```

**Difference from /knowledge:**
- `/context` — files loaded for this session only, counts against token limit
- `/knowledge` — files indexed persistently, searched semantically, survives restarts

---

### /knowledge
Manage the persistent knowledge base — indexed content that survives across sessions and is searched semantically.

```
/knowledge show                     → List all knowledge base entries
/knowledge add <name> <path>        → Index files or directories
/knowledge remove <name>            → Remove an entry by name
/knowledge update <path>            → Re-index updated content
/knowledge clear                    → Wipe the entire knowledge base
/knowledge cancel                   → Cancel a background indexing operation
```

**When to use:**
- Index your entire codebase once, then ask questions about it across all future sessions
- Store documentation, runbooks, or architecture notes for persistent reference
- Build a searchable knowledge base from multiple projects

**Examples:**
```
/knowledge add project-src src/
/knowledge add api-docs docs/api/
/knowledge add runbooks ops/runbooks/

# Now ask:
"How does the auth middleware work?"
"What's the deployment process for production?"
```

> **Enable first:** `kiro-cli settings chat.enableKnowledge true`

**How it works:** Files are indexed using semantic embeddings (MiniLLM) + keyword search (BM25). When you ask a question, Kiro searches the knowledge base and injects relevant snippets into context automatically.

---

## 6. Code Intelligence

### /code
Manage the code intelligence workspace — AST parsing, symbol search, and codebase understanding.

```
/code status    → Show workspace indexing status
/code init      → Initialize code intelligence for the current directory
/code logs      → View code intelligence logs (useful for debugging)
/code overview  → High-level codebase structure (languages, file counts, key files)
/code summary   → Summarize what the codebase does
```

**When to use:**
- `/code init` — first time using Kiro in a new project
- `/code overview` — quickly orient yourself in an unfamiliar codebase
- `/code status` — if symbol search or AST features aren't working

**What code intelligence enables:**
- Find symbol definitions (functions, classes, methods) by name
- AST-based structural search (find all functions that call X)
- Understand code structure without reading every file

---

## 7. Hooks

See [/hooks](#hooks) in the Tools & MCP section above.

---

## 8. Input & Editing

### /editor
Open your system editor (`$VISUAL` or `$EDITOR`) to compose a multi-line prompt. Content is sent when you save and close.

```
/editor
/editor <initial text>
```

**When to use:**
- Writing long, structured prompts with multiple sections
- Pasting large code blocks or configs
- Crafting detailed instructions that need proper formatting

**Example:**
```
/editor Please review the following architecture decision:
```
Opens your editor (vim, nano, VS Code, etc.) pre-filled with that text.

**Setup:** Set your preferred editor:
```bash
export EDITOR=vim
# or
export EDITOR="code --wait"
```

---

### /reply
Open your editor pre-filled with the last assistant message so you can quote and respond to specific parts.

```
/reply
```

**When to use:** Detailed follow-ups where you want to reference or quote specific parts of the previous response.

---

### /paste
Paste an image from your clipboard directly into the chat.

```
/paste
```

**When to use:** Share screenshots, UI mockups, diagrams, error screenshots, or any visual content for the agent to analyze.

---

## 9. Spawning Sessions

### /spawn
Spawn a new parallel agent session with a specific task. Runs in the background while you keep working.

```
/spawn <task description>
```

**When to use:**
- Offload a long-running research or analysis task
- Run multiple investigations in parallel
- Keep your main session free while background work happens

**Examples:**
```
/spawn Analyze test coverage across the entire codebase and identify gaps
/spawn Review the auth module for security vulnerabilities
/spawn Research best practices for database connection pooling in Node.js
```

**Monitor background sessions:** Press `Ctrl+G` to open the crew monitor and see what all sessions are doing in real-time.

**How it connects to subagents:** `/spawn` is the user-facing trigger for the `subagent` tool. When you spawn a session, it creates a new agent session that runs independently and reports back.

---

## 10. UI & Display

### /theme
Pick a color theme for the terminal UI.

```
/theme
```

**Options:** Auto (detects terminal background), Dark, Light, Custom (separate prompt/response/diff color presets).

---

### /copy
Copy the last assistant response to your clipboard.

```
/copy
```

**When to use:** Quickly grab a code snippet, explanation, or command from the last response without selecting text manually.

---

## 11. Info & Feedback

### /help
Show all available slash commands with their usage syntax in a searchable overlay panel.

```
/help
```

---

### /prompts
List and use saved prompt templates.

```
/prompts                    → List all available prompts
/prompts <prompt-name>      → Use a specific prompt template
```

**When to use:** Reuse complex prompt patterns. Store your best prompts as templates to avoid retyping them.

---

### /usage
Show billing and token usage information for the current session and account.

```
/usage
```

---

### /feedback
Submit feedback, feature requests, or bug reports directly from the CLI.

```
/feedback
```

---

### /quit / /exit
Exit the application.

```
/quit
/exit
```

---

## 12. Keyboard Shortcuts

These work in the TUI (default interface) without typing a command:

| Shortcut | Action | When to use |
|----------|--------|-------------|
| `Ctrl+G` | Crew monitor — see all active agent sessions | Monitor `/spawn` sessions, subagent pipelines |
| `Ctrl+X` | Activity tray — task progress + message queue | See queued messages, track task list |
| `Ctrl+R` | Reverse search through command history | Find a previous prompt you typed |
| `Ctrl+O` | Toggle collapsible tool output | Hide/show verbose tool output |
| `Ctrl+_` | Undo input (100-entry stack) | Undo accidental edits in the input box |
| `Shift+Enter` | Multi-line input | Write multi-line prompts inline |
| `Esc` | Dismiss overlay panels | Close `/help`, `/tools`, `/context` panels |
| `y` | Approve tool permission prompt | Allow a tool to run |
| `n` | Deny tool permission prompt | Block a tool from running |
| `t` | Trust tool (approve + remember) | Approve and auto-approve future uses |

---

## 13. Quick Decision Guide

| I want to... | Command |
|-------------|---------|
| Save my conversation | `/chat save <name>` |
| Resume a saved conversation | `/chat load <name>` |
| Start fresh | `/chat new` |
| Free up context (keep summary) | `/compact` |
| Free up context (wipe clean) | `/clear` |
| Switch to a smarter model | `/model` |
| Add files to this session's context | `/context add <path>` |
| Index codebase for all future sessions | `/knowledge add <name> <path>` |
| Stop "Allow?" prompts | `/tools trust-all` |
| Run a task in the background | `/spawn <task>` |
| Get help with Kiro | `/guide <question>` |
| Make a plan before coding | `/plan <idea>` |
| Write a long/complex prompt | `/editor` |
| Share a screenshot with the agent | `/paste` |
| See all active sessions | `Ctrl+G` |
| Check token usage | `/context` |
| See connected MCP servers | `/mcp` |
| See configured hooks | `/hooks` |

---

## Command Categories at a Glance

```
Conversation:  /chat save  /chat load  /chat new  /clear  /compact  /transcript
Agents:        /agent  /plan  /guide
Models:        /model
Tools:         /tools  /mcp  /hooks
Context:       /context  /knowledge
Code:          /code
Input:         /editor  /reply  /paste  /copy
Sessions:      /spawn
UI:            /theme
Info:          /help  /prompts  /usage  /feedback  /quit
```
