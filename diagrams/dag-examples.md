# DAG Patterns — Visual Examples

## Pattern 1: All Parallel (no dependencies)

```
┌─────────┐  ┌─────────┐  ┌─────────┐
│ Stage A │  │ Stage B │  │ Stage C │
└─────────┘  └─────────┘  └─────────┘
   start        start        start
   immediately  immediately  immediately
```

Config:
```json
{
  "stages": [
    {"name": "A", "role": "kiro_default", "prompt_template": "Do task A"},
    {"name": "B", "role": "kiro_default", "prompt_template": "Do task B"},
    {"name": "C", "role": "kiro_default", "prompt_template": "Do task C"}
  ]
}
```

---

## Pattern 2: Sequential Chain

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│ Stage A │ ──▶ │ Stage B │ ──▶ │ Stage C │
└─────────┘     └─────────┘     └─────────┘
  starts          waits for A     waits for B
```

Config:
```json
{
  "stages": [
    {"name": "A", "role": "kiro_default", "prompt_template": "Research"},
    {"name": "B", "role": "kiro_default", "prompt_template": "Implement", "depends_on": ["A"]},
    {"name": "C", "role": "kiro_default", "prompt_template": "Review", "depends_on": ["B"]}
  ]
}
```

---

## Pattern 3: Fan-Out / Fan-In (Diamond)

```
              ┌─────────┐
         ┌──▶ │ Stage B │ ──┐
         │    └─────────┘   │
┌─────────┐                 ▼   ┌─────────┐
│ Stage A │ ──┐         ┌────── │ Stage D │
└─────────┘   │         │       └─────────┘
              ▼         │
         ┌─────────┐   │
         │ Stage C │ ──┘
         └─────────┘

A runs first → B and C run in parallel → D waits for both B and C
```

Config:
```json
{
  "stages": [
    {"name": "A", "role": "kiro_default", "prompt_template": "Gather requirements"},
    {"name": "B", "role": "kiro_default", "prompt_template": "Design frontend", "depends_on": ["A"]},
    {"name": "C", "role": "kiro_default", "prompt_template": "Design backend", "depends_on": ["A"]},
    {"name": "D", "role": "kiro_default", "prompt_template": "Integrate", "depends_on": ["B", "C"]}
  ]
}
```

---

## Pattern 4: Multiple Entry Points

```
┌─────────┐       ┌─────────┐
│ Stage A │       │ Stage B │     ← both start immediately
└────┬────┘       └────┬────┘
     │                 │
     └────────┬────────┘
              ▼
         ┌─────────┐
         │ Stage C │              ← waits for A AND B
         └─────────┘
```

---

## How to Read a DAG

1. Find nodes with NO incoming arrows → they start immediately (parallel)
2. Follow the arrows → each arrow means "must finish before"
3. A node starts ONLY when ALL its incoming arrows are satisfied
4. Nodes at the same "level" with no dependencies between them run in parallel

## Invalid DAGs (cycles)

```
INVALID: A -> B -> C -> A        (circular — infinite loop)
INVALID: A -> B -> A             (mutual dependency)
INVALID: A -> A                  (self-dependency)
```

These will be rejected by Kiro.
