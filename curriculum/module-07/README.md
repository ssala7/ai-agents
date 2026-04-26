# Module 7: Multi-Agent — DAGs & Subagents

> **Key Question:** How do multiple agents coordinate?

---

## 7.1 Why Multiple Agents?

Some tasks are too big or too diverse for one agent:

```
Single agent:
  "Compare Jest vs Vitest vs Mocha"
  → researches Jest... then Vitest... then Mocha... (sequential, slow)

Multiple agents:
  Agent A researches Jest     ─┐
  Agent B researches Vitest   ─┤── all at once (parallel, fast)
  Agent C researches Mocha    ─┘
  Agent D compares results    ← after all three finish
```

## 7.2 DAG — Directed Acyclic Graph

A DAG defines which tasks can run in parallel and which must wait.

**Three rules:**
1. **Directed** — tasks flow one way (A → B, never B → A)
2. **Acyclic** — no loops (A → B → C → A is forbidden)
3. **No dependencies = parallel** — stages without `depends_on` start immediately

```
┌──────────┐  ┌──────────┐  ┌──────────┐
│  Jest    │  │  Vitest  │  │  Mocha   │   ← no deps, all parallel
└────┬─────┘  └────┬─────┘  └────┬─────┘
     │             │             │
     └─────────────┼─────────────┘
                   ▼
            ┌──────────────┐
            │   Compare    │   ← depends_on: [jest, vitest, mocha]
            └──────────────┘
```

## 7.3 Four DAG Patterns

### Pattern 1: All Parallel
```
[A]  [B]  [C]     ← all start immediately
```
Use: independent research tasks

### Pattern 2: Sequential Chain
```
[A] → [B] → [C]   ← each waits for the previous
```
Use: research → implement → review

### Pattern 3: Fan-Out / Fan-In (Diamond)
```
     [A]
    ↙   ↘
  [B]   [C]       ← B and C parallel after A
    ↘   ↙
     [D]           ← D waits for both B and C
```
Use: gather requirements → parallel work → integrate

### Pattern 4: Multiple Entry Points
```
[A]     [B]        ← both start immediately
  ↘   ↙
   [C]             ← waits for both
```
Use: independent inputs feeding one output

## 7.4 Subagent Tool — How It Works

The `subagent` tool creates a DAG pipeline:

```json
{
  "task": "Compare caching solutions",
  "stages": [
    {"name": "redis", "role": "kiro_default", "prompt_template": "Research Redis for {task}"},
    {"name": "memcached", "role": "kiro_default", "prompt_template": "Research Memcached for {task}"},
    {"name": "compare", "role": "kiro_default", "prompt_template": "Compare findings for {task}",
     "depends_on": ["redis", "memcached"]}
  ]
}
```

What happens:
1. Runtime reads the DAG
2. `redis` and `memcached` have no deps → start in parallel
3. Each gets its own session with its own agent
4. When done, each calls `summary()` to report back
5. `compare` sees both are done → starts
6. `compare` calls `summary()` → main agent gets final result

## 7.5 Session Management — Agent Messaging

---

### Try This Now

Spawn a background session and watch it work:

```
/spawn List all files in the current directory and count how many are Python files
```

Now immediately press `Ctrl+G` to open the crew monitor. You will see:
- Your main session (the one you are chatting in)
- The spawned session (running the task you gave it)
- Status indicators showing which is active/idle/done

This is multi-agent coordination in action — two sessions running in parallel, each with their own agent instance.

When the spawned session finishes, its result appears in your main session.

---

Under the hood, agents coordinate via an inbox system:

```
┌─────────────────────────────────────────────┐
│  Main Agent                                  │
│  ├── spawn_session("reviewer-1")             │
│  ├── spawn_session("reviewer-2")             │
│  ├── manage_group(create: "review-team")     │
│  ├── manage_group(add: reviewer-1, reviewer-2)│
│  └── broadcast("review-team", "Start!")      │
│                                              │
│  reviewer-1                reviewer-2        │
│  ├── works...              ├── works...      │
│  ├── send_message(main,    ├── send_message( │
│  │   "Found 2 issues")    │   priority:     │
│  │                         │   "escalation") │
│  └── done                  └── done          │
│                                              │
│  Main Agent                                  │
│  ├── read_messages() → sees both results     │
│  └── interrupt(reviewer-1, "Check SQL too")  │
└─────────────────────────────────────────────┘
```

### Session Commands

| Command | What it does | Analogy |
|---------|-------------|---------|
| `spawn_session` | Create new agent session | Hire a team member |
| `send_message` | DM another session | Slack DM |
| `read_messages` | Check inbox | Read notifications |
| `manage_group` | Group sessions | Create a channel |
| `broadcast` | Message all in group | @channel |
| `interrupt` | Redirect a session | "Drop that, do this" |
| `inject_context` | Silently add info | Pin a doc |
| `revive_session` | Restart terminated session | Re-hire |

## 7.6 /spawn — Manual Parallel Sessions

You can manually create parallel sessions:

```
/spawn Analyze test coverage in src/utils
/spawn Review all failing tests
```

Press `Ctrl+G` to monitor all sessions.

Unlike subagent (which the AI decides to use), `/spawn` is something YOU trigger directly.

## 7.7 How Results Flow Back

Each subagent calls `summary()` when done:

```json
{
  "taskDescription": "Research Redis for caching",
  "contextSummary": "Redis supports strings, hashes, lists, sets...",
  "taskResult": "Redis is best for complex data structures and pub/sub."
}
```

The main agent collects all summaries and synthesizes a final answer.

---

## Exercise 7.1: Design a DAG

Design a DAG for this task: "Audit our web application"

Requirements:
- Security scan and performance test can run in parallel
- Accessibility check can also run in parallel
- Final report needs all three results

Draw the DAG and write the stages JSON.

<details>
<summary>Answer</summary>

```
[security]  [performance]  [accessibility]   ← all parallel
     ↘           ↓            ↙
          [final-report]                      ← waits for all three
```

```json
{
  "task": "Audit our web application",
  "stages": [
    {"name": "security", "role": "kiro_default", "prompt_template": "Security scan for {task}"},
    {"name": "performance", "role": "kiro_default", "prompt_template": "Performance test for {task}"},
    {"name": "accessibility", "role": "kiro_default", "prompt_template": "Accessibility check for {task}"},
    {"name": "final-report", "role": "kiro_default", "prompt_template": "Compile audit report for {task}",
     "depends_on": ["security", "performance", "accessibility"]}
  ]
}
```

</details>

---

## Exercise 7.2: Spot the Invalid DAG

Which of these are valid DAGs?

```
A) [A] → [B] → [C]
B) [A] → [B] → [A]
C) [A] → [B], [A] → [C], [B] → [D], [C] → [D]
D) [A] → [A]
E) [A], [B], [C] (no dependencies)
```

<details>
<summary>Answer</summary>

- **A) Valid** — simple sequential chain
- **B) Invalid** — cycle: A → B → A
- **C) Valid** — diamond pattern (fan-out/fan-in)
- **D) Invalid** — self-dependency
- **E) Valid** — all parallel (no edges = still a valid DAG)

</details>

---

## Exercise 7.3: Try It Live

Ask Kiro something that might trigger subagents:

```
Compare the pros and cons of PostgreSQL vs MySQL vs SQLite for a small web app
```

Watch:
1. Does it use subagents or handle it in a single session?
2. If subagents, press `Ctrl+G` to see the sessions
3. How many rounds did each subagent take?

Then try manual spawning:
```
/spawn List all TODO comments in the current directory
```
Press `Ctrl+G` to monitor it.

---

## Expected Outcomes

After completing this module and its exercises, you should be able to:
- Define what a DAG is and identify valid vs invalid DAGs
- Design a DAG for a multi-step task with parallel and sequential stages
- Use `/spawn` to create a parallel session and monitor it with `Ctrl+G`
- Explain how subagents report results back via the `summary()` tool
- Describe the session messaging system (spawn, send, broadcast, interrupt)

---

## Check Your Understanding

1. What does DAG stand for and what are its three rules?
2. How does the runtime decide which stages run in parallel?
3. How do subagents report results back?
4. What's the difference between `subagent` and `/spawn`?
5. What is `broadcast` used for in session management?

---

## Next → [Module 8: Build Your Own — Hands-On Lab](../module-08/README.md)
