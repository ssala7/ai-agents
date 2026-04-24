# Session Management — Cheat Sheet

## Quick Reference

### Spawn a Session
```json
{"command": "spawn_session", "agent_name": "kiro_default", "task": "Review auth code", "name": "auth-reviewer", "group": "review-team"}
```
Creates a new agent session. Like hiring someone for a specific job.

---

### Send a Message
```json
{"command": "send_message", "target": "auth-reviewer", "message": "Focus on SQL injection risks", "priority": "normal"}
```
Priority options: `normal` | `escalation`

Escalation without a target auto-routes to the parent session.

---

### Read Messages (check inbox)
```json
{"command": "read_messages", "limit": 5}
```

---

### List Sessions
```json
{"command": "list_sessions", "filter": "active"}
```
Filter options: `active` | `idle` | `busy` | `terminated` | `all`

---

### Get Session Status
```json
{"command": "get_session_status", "target": "auth-reviewer", "verbose": true}
```

---

### Interrupt a Session
```json
{"command": "interrupt", "target": "auth-reviewer", "message": "Stop! New priority: check XSS vulnerabilities"}
```
Redirects a running session to a completely new task.

---

### Inject Context (silent)
```json
{"command": "inject_context", "target": "auth-reviewer", "context": "The app uses JWT tokens with RS256 signing"}
```
Adds info without triggering a new turn — like slipping a note under the door.

---

### Manage Groups
```json
// Create a group
{"command": "manage_group", "action": "create", "group": "review-team"}

// Add session to group
{"command": "manage_group", "action": "add", "group": "review-team", "target": "auth-reviewer", "role": "security"}

// Broadcast to all in group
{"command": "manage_group", "action": "broadcast", "group": "review-team", "message": "Submit your findings now"}

// List group members
{"command": "manage_group", "action": "list", "group": "review-team"}

// Remove from group
{"command": "manage_group", "action": "remove", "group": "review-team", "target": "auth-reviewer"}
```

---

### Revive a Terminated Session
```json
{"command": "revive_session", "target": "auth-reviewer", "task": "Now review the password reset flow"}
```
Brings back a finished session with a new task, keeping its name and group.

---

## User-Facing Commands

| Command | What you type | Effect |
|---------|--------------|--------|
| Spawn | `/spawn Analyze test coverage` | Creates parallel session |
| Monitor | `Ctrl+G` | Opens crew monitor (see all sessions) |

---

## Session Lifecycle

```
spawn_session → active → (completes task) → terminated
                  │                              │
                  │ interrupt                     │ revive_session
                  ▼                              ▼
               redirected                    active again
```

---

## Mental Model

Think of sessions as team members in a Slack workspace:

| Concept | Slack Analogy |
|---------|--------------|
| Session | A team member |
| Group | A channel |
| send_message | DM |
| broadcast | @channel |
| interrupt | "Drop everything, new priority" |
| inject_context | Pinning a doc in the channel |
| spawn_session | Hiring a contractor |
| revive_session | Re-engaging a past contractor |

---

# Kiro CLI — Slash Commands Reference

All commands are typed directly in the chat input. Press `/` to see autocomplete suggestions.

---

## Conversation & Sessions

### /chat
Manage conversations — save, load, or start fresh.

```
/chat save <path>          → Save current conversation to a file
/chat save --force <path>  → Overwrite existing file
/chat load <path>          → Load a saved conversation (.json or .zip)
/chat new                  → Start a brand new conversation
/chat new <prompt>         → Start new conversation with an opening message
```

**Why useful:** Never lose a long debugging session. Save it, come back later with `/chat load`.

**Example:**
```
/chat save my-debug-session
# later...
/chat load my-debug-session
```

---

### /clear
Clears the current conversation history from context.

```
/clear
```

**Why useful:** When context gets too long and the model starts losing focus, clearing resets it without quitting.

---

### /compact
Compacts conversation history — summarizes old turns to free up context space.

```
/compact
```

**Why useful:** Keeps the session alive longer without losing the gist of what was discussed. Better than `/clear` when you want continuity.

---

### /transcript
Opens the full conversation in your `$PAGER` (like `less`). Quit with `q`.

```
/transcript
```

**Why useful:** Review everything said in the session without scrolling back through the terminal.

---

## Agents

### /agent
Switch between agents, create new ones, or edit existing configs.

```
/agent                          → List all available agents
/agent <name>                   → Switch to a specific agent
/agent create <name>            → Create a new agent
/agent create <name> --from kiro_default  → Clone from an existing agent
/agent edit <name>              → Edit an agent's JSON config
```

**Built-in agents:**
| Agent | What it does |
|-------|-------------|
| `kiro_default` | General-purpose assistant |
| `kiro_planner` | Breaks ideas into step-by-step plans |
| `kiro_guide` | Answers questions about Kiro CLI itself |

**Why useful:** Switch to a specialized agent mid-session. E.g., switch to `kiro_planner` when you need to break down a complex task, then back to `kiro_default` to implement it.

---

### /plan
Shortcut to switch to the planner agent with an optional prompt.

```
/plan
/plan Build a REST API with auth and rate limiting
```

**Why useful:** Instantly get a structured implementation plan without manually switching agents.

---

### /guide
Switch to the guide agent for help with Kiro CLI itself. Toggle back by running `/guide` again.

```
/guide
/guide How do I save a conversation?
/guide What tools are available?
```

**Why useful:** Ask Kiro about Kiro. The guide agent searches embedded documentation to answer questions about commands, settings, and features.

---

## Models

### /model
Switch the AI model for the current session.

```
/model                  → Show available models + current selection
/model <model-name>     → Switch to a specific model
```

**Why useful:** Use a faster/cheaper model for simple tasks, switch to a more capable one for complex reasoning — all without restarting.

---

## Tools

### /tools
View and manage tool trust settings.

```
/tools                  → Show all available tools and their trust status
/tools trust-all        → Auto-approve all tools (no more "Allow?" prompts)
/tools trust <name>     → Trust a specific tool
/tools untrust <name>   → Remove trust from a tool
/tools reset            → Reset all trust settings to default
```

**Why useful:** When you're in a flow and don't want to approve every file read, `/tools trust-all` removes the friction. Reset when done for safety.

---

### /mcp
Show all configured MCP (Model Context Protocol) servers.

```
/mcp
```

**Why useful:** Quickly verify which external tool servers are connected and available to the agent.

---

## Context & Knowledge

### /context
Manage files loaded into the agent's context, or check token usage.

```
/context                        → Show current token usage
/context add <path>             → Add a file or glob to context
/context add --force <path>     → Add even if already present
/context remove <path>          → Remove a file from context
/context clear                  → Remove all context files
```

**Why useful:** Manually inject relevant files so the agent has the right information without you having to paste it. E.g., add your `schema.sql` before asking about database queries.

**Example:**
```
/context add src/auth/**/*.ts
/context add docs/api-spec.md
```

---

### /knowledge
Manage the persistent knowledge base — indexed content that survives across sessions.

```
/knowledge show                     → List all knowledge base entries
/knowledge add <name> <path>        → Index files/directories
/knowledge remove <name>            → Remove an entry
/knowledge update <path>            → Re-index updated content
/knowledge clear                    → Wipe the entire knowledge base
/knowledge cancel                   → Cancel background indexing
```

**Why useful:** Index your entire codebase once, then search it semantically across all future sessions. Unlike `/context`, knowledge persists between restarts.

**Example:**
```
/knowledge add project-src src/
/knowledge add api-docs docs/api/
# Now ask: "How does the auth middleware work?" — it searches indexed content
```

> Enable first: `kiro-cli settings chat.enableKnowledge true`

---

## Code Intelligence

### /code
Manage the code intelligence workspace (AST parsing, symbol search).

```
/code status    → Show workspace status
/code init      → Initialize code intelligence for current directory
/code logs      → View code intelligence logs
/code overview  → High-level codebase structure
/code summary   → Summarize the codebase
```

**Why useful:** Gives the agent deep structural understanding of your code — not just text search, but actual AST-level symbol awareness.

---

## Hooks

### /hooks
View all configured lifecycle hooks for the current agent.

```
/hooks
```

**Hook triggers:**
| Trigger | When it fires |
|---------|--------------|
| `agentSpawn` | Agent starts up |
| `userPromptSubmit` | You send a message |
| `preToolUse` | Before a tool runs (exit 2 = block it) |
| `postToolUse` | After a tool runs |
| `stop` | Agent finishes responding |

**Why useful:** Verify what automation is running around your agent's actions — e.g., auto-lint after file writes, auto-test after bash commands.

---

## Input & Editing

### /editor
Open your `$EDITOR` (vim, nano, VS Code, etc.) to compose a multi-line prompt.

```
/editor
/editor Please review the following changes:
```

**Why useful:** Write long, structured prompts with proper formatting instead of cramming everything into one line.

---

### /reply
Open your editor pre-filled with the last assistant message so you can quote and respond to it.

```
/reply
```

**Why useful:** Useful for detailed follow-ups — you can reference specific parts of the previous response.

---

### /paste
Paste an image from your clipboard directly into the chat.

```
/paste
```

**Why useful:** Share screenshots, diagrams, or UI mockups with the agent for visual analysis.

---

## Prompts

### /prompts
List and use saved prompt templates.

```
/prompts                    → List all available prompts
/prompts <prompt-name>      → Use a specific prompt template
```

**Why useful:** Reuse complex prompt patterns without retyping them. Store your best prompts as templates.

---

## Spawning Sessions

### /spawn
Spawn a new parallel agent session with a specific task. The session runs in the background.

```
/spawn Analyze test coverage across the entire codebase
/spawn Review the auth module for security issues
```

**Why useful:** Offload a long-running task to a background agent while you keep working in the main session. Press `Ctrl+G` to monitor all running sessions.

---

## UI & Display

### /theme
Pick a color theme for the terminal UI.

```
/theme
```

Options: Auto, Dark, Light, Custom (with separate prompt/response/diff color presets).

---

### /copy
Copy the last assistant response to your clipboard.

```
/copy
```

---

## Info & Feedback

### /help
Show all available slash commands with usage syntax.

```
/help
```

---

### /usage
Show billing and token usage information.

```
/usage
```

---

### /feedback
Submit feedback, feature requests, or bug reports.

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

## Keyboard Shortcuts (TUI)

| Shortcut | Action |
|----------|--------|
| `Ctrl+G` | Open crew monitor — see all active agent sessions |
| `Ctrl+X` | Open activity tray — task progress + message queue |
| `Ctrl+R` | Reverse search through command history |
| `Ctrl+O` | Toggle collapsible tool output |
| `Ctrl+_` | Undo input (100-entry stack) |
| `Shift+Enter` | Multi-line input |
| `Esc` | Dismiss overlay panels |
| `y / n / t` | Approve / deny / trust tool permission prompts |

---

## Quick Decision Guide

| I want to... | Use |
|-------------|-----|
| Save my conversation | `/chat save <name>` |
| Free up context space | `/compact` |
| Start fresh | `/clear` or `/chat new` |
| Switch to a smarter model | `/model` |
| Add files to context | `/context add <path>` |
| Index codebase for search | `/knowledge add <name> <path>` |
| Stop approval prompts | `/tools trust-all` |
| Run a task in background | `/spawn <task>` |
| Get help with Kiro | `/guide <question>` |
| Make a plan | `/plan <idea>` |
| Write a long prompt | `/editor` |
