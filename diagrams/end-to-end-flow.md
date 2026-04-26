# End-to-End Flow: How Everything Connects

This walks through exactly what happens from the moment you type something to when you get a response.

---

## The Big Picture

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   YOU type: "Compare Jest vs Vitest for my project"                 │
│                                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 1: ACP LAYER                                                  │
│                                                                     │
│  Your input becomes a JSON-RPC message:                             │
│  ┌────────────────────────────────────────────┐                     │
│  │ { "method": "session/prompt",              │                     │
│  │   "params": {                              │                     │
│  │     "prompt": "Compare Jest vs Vitest..." }}│                     │
│  └────────────────────────────────────────────┘                     │
│  Sent over stdin → Kiro agent process                               │
│                                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 2: AGENT PROCESSES YOUR REQUEST                               │
│                                                                     │
│  The active agent (e.g. kiro_default) receives the prompt.          │
│  Its config defines:                                                │
│    • prompt → "You are a helpful assistant..."                      │
│    • tools  → [read, write, subagent, ...]                   │
│    • hooks  → agentSpawn, preToolUse, etc.                          │
│                                                                     │
│  [Hook] userPromptSubmit hooks run first                            │
│                                                                     │
│  The AI decides: "This needs parallel research. I'll use subagent." │
│                                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 3: SUBAGENT TOOL CREATES A DAG                                │
│                                                                     │
│  The agent calls the subagent tool with:                            │
│  ┌──────────────────────────────────────────────────────┐           │
│  │ { "task": "Compare Jest vs Vitest",                  │           │
│  │   "stages": [                                        │           │
│  │     { "name": "jest",   "prompt_template": "..." },  │           │
│  │     { "name": "vitest", "prompt_template": "..." },  │           │
│  │     { "name": "compare","prompt_template": "...",    │           │
│  │       "depends_on": ["jest", "vitest"] }             │           │
│  │   ]                                                  │           │
│  │ }                                                    │           │
│  └──────────────────────────────────────────────────────┘           │
│                                                                     │
│  [Hook] preToolUse for "subagent" tool                              │
│                                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 4: DAG SCHEDULER RESOLVES DEPENDENCIES                       │
│                                                                     │
│  The scheduler looks at the DAG:                                    │
│                                                                     │
│    jest ──────────┐                                                 │
│    (no deps)      ├──▶ compare (depends_on: jest, vitest)           │
│    vitest ────────┘                                                 │
│    (no deps)                                                        │
│                                                                     │
│  Decision:                                                          │
│    • jest + vitest → START NOW (parallel)                           │
│    • compare → WAIT for both                                        │
│                                                                     │
└──────────┬───────────────────────────────┬──────────────────────────┘
           │                               │
           ▼                               ▼
┌─────────────────────┐     ┌─────────────────────┐
│  STEP 5a: SESSION   │     │  STEP 5b: SESSION   │
│  "jest" spawned     │     │  "vitest" spawned    │
│                     │     │                      │
│  • New session      │     │  • New session       │
│  • Gets own agent   │     │  • Gets own agent    │
│  • Has own inbox    │     │  • Has own inbox     │
│  • Runs its task    │     │  • Runs its task     │
│                     │     │                      │
│  Researches Jest... │     │  Researches Vitest...|
│                     │     │                      │
│  Calls summary():   │     │  Calls summary():    │
│  ┌───────────────┐  │     │  ┌───────────────┐   │
│  │ taskResult:   │  │     │  │ taskResult:   │   │
│  │ "Jest is..."  │  │     │  │ "Vitest is.." │   │
│  └───────────────┘  │     │  └───────────────┘   │
└─────────┬───────────┘     └──────────┬───────────┘
          │                            │
          └────────────┬───────────────┘
                       │ both done!
                       ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 6: "compare" SESSION STARTS                                   │
│                                                                     │
│  DAG scheduler sees jest ✓ and vitest ✓ → starts "compare"         │
│                                                                     │
│  • Receives summaries from both previous stages                     │
│  • Synthesizes a comparison                                         │
│  • Calls summary() with final result                                │
│                                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 7: RESULTS FLOW BACK                                          │
│                                                                     │
│  Main agent receives all summaries.                                 │
│                                                                     │
│  [Hook] postToolUse for "subagent" tool                             │
│  [Hook] stop (agent finished responding)                            │
│                                                                     │
│  Response sent back via ACP:                                        │
│  ┌────────────────────────────────────────────┐                     │
│  │ session/notification:                      │                     │
│  │   AgentMessageChunk → streaming response   │                     │
│  │   TurnEnd → done                           │                     │
│  └────────────────────────────────────────────┘                     │
│                                                                     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   YOU see: "Here's my comparison of Jest vs Vitest..."              │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Simple Flow (No Subagents)

Most requests don't need subagents. Here's the simpler path:

```
You type → ACP → Agent → uses tools directly → ACP → You see response

Example: "Read my package.json"

  YOU ──▶ ACP ──▶ Agent ──▶ read("package.json") ──▶ Agent ──▶ ACP ──▶ YOU
                    │                                      ▲
                    │         preToolUse hook fires         │
                    └──────────────────────────────────────┘
```

---

## /spawn Flow (Manual Parallel)

```
You type: /spawn Analyze test coverage

  Main Session (you keep chatting)
       │
       ├──▶ Spawned Session: "Analyze test coverage"
       │         │
       │         ├── reads files, runs commands
       │         └── finishes → results in crew monitor
       │
       └── You continue your conversation normally

  Press Ctrl+G to see both sessions
```

---

## Session Messaging Flow

```
Main Agent
  │
  ├── spawn_session("reviewer-1", group: "reviewers")
  ├── spawn_session("reviewer-2", group: "reviewers")
  │
  ├── broadcast to "reviewers": "Start reviewing auth module"
  │         │                          │
  │    reviewer-1 works          reviewer-2 works
  │         │                          │
  │    send_message(priority:     send_message(target: main,
  │      "escalation")             "Found 3 issues")
  │         │                          │
  │    ◀────┘                    ◀─────┘
  │
  ├── read_messages() → sees both results
  │
  └── interrupt("reviewer-1", "Check the SQL queries too")
            │
       reviewer-1 redirected to new task
```

---

## Where State Lives

```
~/.kiro/
├── agents/                    ← Agent config files (global)
│   ├── rust-dev.json
│   └── python-dev.json
├── sessions/
│   └── cli/                   ← Session data
│       ├── <id>.json          ← Session metadata
│       └── <id>.jsonl         ← Conversation event log
└── ...

.kiro/                         ← Project-local (takes precedence)
├── agents/
│   └── project-helper.json
└── skills/
    └── SKILL.md
```

---

## Concept Map

```
┌──────────────────────────────────────────────────────────┐
│                    CONCEPTS                                │
├──────────────┬───────────────────────────────────────────┤
│ Agent Config │ The "who" — defines personality + tools    │
│              │ JSON file in ~/.kiro/agents/               │
├──────────────┼───────────────────────────────────────────┤
│ Session      │ The "where" — running instance of agent    │
│              │ Has inbox, history, persisted to disk       │
├──────────────┼───────────────────────────────────────────┤
│ ACP          │ The "how" — JSON-RPC protocol over stdio   │
│              │ Client ↔ Agent communication                │
├──────────────┼───────────────────────────────────────────┤
│ DAG          │ The "plan" — dependency graph               │
│              │ No deps = parallel, deps = wait             │
├──────────────┼───────────────────────────────────────────┤
│ Subagent     │ The "team" — spawns agent pipeline          │
│              │ Uses DAG to schedule stages                 │
├──────────────┼───────────────────────────────────────────┤
│ Hooks        │ The "rules" — scripts at lifecycle points   │
│              │ Can block, log, validate, inject context    │
├──────────────┼───────────────────────────────────────────┤
│ MCP Servers  │ The "extensions" — external tool providers  │
│              │ Git, GitHub, databases, custom APIs          │
├──────────────┼───────────────────────────────────────────┤
│ Tools        │ The "hands" — what agents actually do       │
│              │ Read, write, search, execute, fetch          │
└──────────────┴───────────────────────────────────────────┘
```
