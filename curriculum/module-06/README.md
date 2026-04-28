# Module 6: Sessions & Memory

> **Key Question:** How does an agent remember things?

---

## 6.1 Two Types of Memory

```
┌─────────────────────────────────────────────────────────┐
│  SHORT-TERM: Context Window                              │
│  • This session only                                     │
│  • Everything you said + every tool result                │
│  • Has a size limit (~200K tokens)                       │
│  • Automatically included — not "searched"               │
│                                                          │
│  Like: a whiteboard in a meeting room                    │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  LONG-TERM: Knowledge Base                               │
│  • Persists across sessions                              │
│  • Files, docs, notes you explicitly indexed             │
│  • Unlimited size (stored on disk)                       │
│  • Searched on demand (not always included)              │
│                                                          │
│  Like: a filing cabinet you can search                   │
└─────────────────────────────────────────────────────────┘
```

## 6.2 Context Window (Short-Term)

Every message you send, the model sees the ENTIRE conversation so far:

```
┌─────────────────────────────────────────┐
│          Context Window                  │
│                                          │
│  [System prompt]                         │
│  [Tool definitions]                      │
│  [Resources from agent config]           │
│  [Your message 1]                        │
│  [My response 1]                         │
│  [Tool call: grep → result]              │
│  [Your message 2]                        │
│  [My response 2]                         │
│  ...                                     │
│  [Your latest message]                   │
│                                          │
│  ████████████░░░░░  ~75% full            │
└─────────────────────────────────────────┘
```

This is NOT "checked" or "searched" — it IS the input. Every time the model runs, it sees all of this.

**When it fills up:**
- `/compact` — AI summarizes old messages, frees space
- `/clear` — wipes everything, fresh start
- `/context` — check how full it is

---

### Try This Now

Run this in Kiro to see your context window usage:

```
/context
```

You will see a breakdown of how many tokens are used by: system prompt, tool definitions, conversation history, and resources. This is the "whiteboard" — everything the model sees on every turn.

Now have a short conversation (ask 2-3 questions), then run `/context` again. Watch the numbers grow. That is your short-term memory filling up.

If you want to see compaction in action, run:
```
/compact
```

Then `/context` again — the usage drops because old messages were summarized.

---

## 6.3 What is a Session?

A session = a running conversation with its full history.

```
Session "abc-123":
  Created: 2026-04-21 10:00
  Agent: kiro_default
  Messages: 47
  Tool calls: 23
  Status: active
```

Sessions are persisted to disk:
```
~/.kiro/sessions/cli/
├── abc-123.json       ← metadata (agent, model, timestamps)
└── abc-123.jsonl      ← event log (every message, tool call, result)
```

**Session commands:**
```
/chat new              → start a fresh session
/chat save <path>      → save current session
/chat load <path>      → load a previous session
```

## 6.4 Knowledge Base (Long-Term)

Enable it:
```bash
kiro-cli settings chat.enableKnowledge true
```

Then index content:
```
"Index my docs folder"     → knowledge.add("project-docs", "docs/")
"Index this README"        → knowledge.add("readme", "README.md")
```

Later (even in a new session):
```
"How does auth work?"      → knowledge.search("auth") → finds relevant docs
```

### Two Search Modes

| Mode | How it works | Best for |
|------|-------------|----------|
| Fast (BM25) | Keyword matching | Logs, configs, exact terms |
| Best (Semantic) | Understands meaning | Docs, research, natural language |

```bash
kiro-cli settings knowledge.indexType Fast    # or Best
```

### Agent Isolation

Each agent has its own knowledge base:
```
knowledge_bases/
├── kiro_default/        ← default agent's knowledge
├── rust-dev/            ← rust-dev agent's knowledge
└── python-dev/          ← python-dev agent's knowledge
```

Agent A cannot see Agent B's knowledge.

## 6.5 Context vs Knowledge — When Each Is Used

```
You type: "What did we discuss about auth?"
                │
                ▼
┌──────────────────────────────────────────┐
│ Context window already contains:          │ ← checked automatically
│  • all messages from THIS session         │    (it's the input itself)
│  • if auth was discussed, it's here       │
└──────────────────────────────────────────┘
                │
                ▼
         Was it in context?
        ┌───────┴───────┐
        ▼               ▼
       YES              NO
   Answer from       Search knowledge base?
   context           (if enabled)
                        │
                        ▼
                  knowledge.search("auth")
                        │
                  Found in indexed docs?
                  ┌─────┴─────┐
                  ▼           ▼
                 YES          NO
              Answer from   "I don't have
              knowledge     that information"
```

## 6.6 The Compaction Process

When context gets full:

```
Before /compact:
┌──────────────────────────────────────┐
│ Message 1: "Set up the project"      │
│ Response 1: [created files...]       │
│ Message 2: "Add authentication"      │
│ Response 2: [wrote auth code...]     │
│ Message 3: "Fix the login bug"       │
│ Response 3: [debugged, fixed...]     │
│ Message 4: "Now add tests"           │  ← 95% full!
│ ...                                  │
└──────────────────────────────────────┘

After /compact:
┌──────────────────────────────────────┐
│ [AI Summary]: Set up project with    │  ← compressed
│ auth module. Fixed login bug in      │
│ src/auth.py line 42. Key files:      │
│ src/auth.py, src/login.py, tests/    │
│                                      │
│ Message 4: "Now add tests"           │  ← recent kept
│ ...                                  │
│                                      │  ← 30% full!
└──────────────────────────────────────┘
```

---

## Exercise 6.1: Context or Knowledge?

Where would the agent find the answer?

| Question | Context or Knowledge? |
|----------|---------------------|
| "What file did you just edit?" | ? |
| "What does our API documentation say about rate limits?" (indexed last week) | ? |
| "What was the error message from the last test run?" | ? |
| "What's in the company style guide?" (never discussed, but indexed) | ? |

<details>
<summary>Answer</summary>

| Question | Where |
|----------|-------|
| "What file did you just edit?" | **Context** — it's in this session's history |
| "API docs about rate limits" | **Knowledge** — indexed last week, not in current session |
| "Error from last test run" | **Context** — if it was this session. Otherwise lost. |
| "Company style guide" | **Knowledge** — indexed but never discussed |

</details>

---

## Exercise 6.2: Check Your Context

Run these commands:
```
/context
```
See how full your context window is.

```
/compact
```
Watch it summarize and free space.

```
/context
```
Compare before and after.

---

## Exercise 6.3: Use the Knowledge Base (Hands-On)

This exercise demonstrates the full knowledge base workflow: index → search → cross-session persistence.

> **Note:** The knowledge base works with the default agent (`kiro_default`). Custom agents may not fully support knowledge indexing. Use `kiro_default` for this exercise.

### Step 1: Enable the knowledge base

```bash
kiro-cli settings chat.enableKnowledge true
```

### Step 2: Switch to the default agent

```
/agent kiro_default
```

### Step 3: Index some content

```
/knowledge add curriculum ~/personal/ai-agents/curriculum
```

Wait for indexing to complete. Check what's indexed:
```
/knowledge show
```

You should see your indexed content listed with a name and file count.

### Step 4: Search the knowledge base

Just ask naturally — Kiro searches the knowledge base automatically:

```
What does Module 3 cover?
```

It should answer from the indexed curriculum without needing to read the files directly.

### Step 5: Test cross-session persistence

Start a brand new session:
```
/chat new
```

Now ask:
```
What topics are covered in Module 4?
```

Kiro answers from the knowledge base — proving it persists across sessions.

### Step 6: Manage your knowledge base

```
/knowledge show     — see what's indexed
/knowledge remove   — remove indexed content
/knowledge clear    — remove everything
/knowledge update   — refresh existing content
```

### What you learned

- Knowledge base is local, free, and persists across sessions
- `/knowledge add` indexes files; searching happens automatically when you ask questions
- The knowledge base works with `kiro_default`; custom agents may have limited support
- Context = this session's conversation. Knowledge = indexed content available anytime.

---

## Expected Outcomes

After completing this module and its exercises, you should be able to:
- Explain the difference between context (short-term) and knowledge (long-term)
- Check context window usage with `/context` and free space with `/compact`
- Index files into the knowledge base and search them in a new session
- Describe how agent isolation works (each agent has its own knowledge base)

---

## Check Your Understanding

1. What's the difference between context and knowledge?
2. Is the context window "searched"? Why or why not?
3. What happens when the context window fills up?
4. Can Agent A access Agent B's knowledge base?
5. When is the knowledge base searched?

---

## Next → [Module 7: Multi-Agent — DAGs & Subagents](../module-07/README.md)
