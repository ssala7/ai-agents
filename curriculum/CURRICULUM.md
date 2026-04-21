# AI Agent Architecture — Teaching Curriculum

> A structured course to understand how AI agents work, from zero to building your own.
> Uses Kiro CLI as the reference implementation, but concepts apply to any agent system.

---

## Who Is This For?

- Developers who want to understand AI agent internals
- Team leads evaluating agent frameworks
- Anyone curious about how tools like Kiro, Cursor, Copilot work under the hood

## Prerequisites

- Basic programming knowledge (any language)
- Terminal/command-line familiarity
- No AI/ML background needed

## Duration

- 8 modules, ~30-45 minutes each
- Can be taught as a 1-day workshop or 4-week course (2 modules/week)

---

## Curriculum Map

```
Module 1          Module 2          Module 3          Module 4
What is an    →   Runtime vs    →   Tools: Giving →   How AI Decides
AI Agent?         The Brain         AI Hands          What To Do

Module 5          Module 6          Module 7          Module 8
Protocols:    →   Sessions &    →   Multi-Agent:  →   Build Your Own
ACP & JSON-RPC    Memory            DAGs & Subagents  (Hands-On Lab)
```

### Dependency Flow

```
[1: Agent] → [2: Runtime vs Brain] → [3: Tools] → [4: Decision Making]
                                          ↓
[5: Protocols] → [6: Sessions] → [7: Multi-Agent] → [8: Lab]
```

Modules 1-4 are conceptual. Modules 5-8 are progressively hands-on.

---

## Module Overview

| # | Module | Key Question | Duration |
|---|--------|-------------|----------|
| 1 | What is an AI Agent? | How is an agent different from a chatbot? | 30 min |
| 2 | The Runtime vs The Brain | What does the runtime do vs the model? | 30 min |
| 3 | Tools — Giving AI Hands | How does an agent interact with the real world? | 45 min |
| 4 | How AI Decides What To Do | How does the model pick which tool to call? | 30 min |
| 5 | Protocols — ACP & JSON-RPC | How do components talk to each other? | 45 min |
| 6 | Sessions & Memory | How does an agent remember things? | 30 min |
| 7 | Multi-Agent — DAGs & Subagents | How do multiple agents coordinate? | 45 min |
| 8 | Build Your Own — Hands-On Lab | Build a custom tool + agent from scratch | 60 min |

---

## Teaching Tips

### For Instructors

1. **Start each module with the "Key Question"** — let students discuss before teaching
2. **Use the analogies** — every module has real-world analogies
3. **Run the exercises live** — students should see real output
4. **Pause at checkpoints** — each module has "Check Your Understanding" questions
5. **Module 8 is the payoff** — everything clicks when they build it themselves

### For Self-Learners

1. Read each module in order
2. Do every exercise (don't skip)
3. Answer the checkpoint questions before moving on
4. Module 8 ties everything together

---

## Files

```
curriculum/
├── CURRICULUM.md                    ← You are here
├── module-01/README.md              ← What is an AI Agent?
├── module-02/README.md              ← The Runtime vs The Brain
├── module-03/README.md              ← Tools — Giving AI Hands
├── module-04/README.md              ← How AI Decides What To Do
├── module-05/README.md              ← Protocols — ACP & JSON-RPC
├── module-06/README.md              ← Sessions & Memory
├── module-07/README.md              ← Multi-Agent — DAGs & Subagents
└── module-08/README.md              ← Build Your Own — Hands-On Lab
```

## Supporting Materials

The `kiro-concepts-demo/` folder also contains:
- `hands-on/` — Working MCP server + agent config for Module 8
- `diagrams/` — Visual DAG patterns and end-to-end flow
- `examples/` — Pipeline configs (parallel, sequential, fan-out)
- `cheatsheets/` — Quick reference cards
- `guides/` — Agent configuration deep-dive

---

## Start → [Module 1: What is an AI Agent?](module-01/README.md)
