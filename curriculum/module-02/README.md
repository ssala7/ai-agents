# Module 2: The Runtime vs The Brain

> **Key Question:** What does the runtime do vs what does the model do?

---

## 2.1 The Core Insight

An AI agent is NOT just a model. It's two things working together:

```
┌──────────────────────────────────────────────────────────┐
│  RUNTIME (Kiro)              │  MODEL (Claude)            │
│                              │                            │
│  Smart about orchestration   │  Smart about understanding │
│  Dumb about content          │  Dumb about execution      │
└──────────────────────────────┴────────────────────────────┘
```

**Analogy: A surgeon and an operating room**

| Operating Room (Runtime) | Surgeon (Model) |
|---|---|
| Lights, monitors, tools on tray | Decides what to cut, where, when |
| Nurses hand instruments | Interprets what they see |
| Tracks patient vitals | Makes judgment calls |
| Sterilizes equipment | Adapts when things go wrong |

The operating room doesn't know medicine. The surgeon can't operate without the room.

## 2.2 What the Runtime Does (Before the Model Sees Anything)

```
You type: "find bugs in my auth code"
                │
                ▼
┌─────────────────────────────────────────────────────┐
│  KIRO RUNTIME — Step by step:                        │
│                                                      │
│  1. Receive input via ACP protocol                   │
│  2. Run userPromptSubmit hooks (if configured)       │
│  3. Look up active agent config                      │
│     → which model? which tools? which permissions?   │
│  4. Assemble the context payload:                    │
│     ┌──────────────────────────────────────┐         │
│     │ System prompt (from agent config)    │         │
│     │ Tool definitions (names + schemas)   │         │
│     │ Resources (loaded files)             │         │
│     │ Conversation history (all turns)     │         │
│     │ Hook outputs                         │         │
│     │ Your new message                     │         │
│     └──────────────────────────────────────┘         │
│  5. Send assembled payload to the model              │
│                                                      │
│  None of this requires intelligence.                 │
│  It's plumbing.                                      │
└──────────────────────────────────────────────────────┘
                │
                ▼
          Model receives it
```

## 2.3 What the Model Does

```
Model receives the assembled context
                │
                ▼
┌─────────────────────────────────────────────────────┐
│  MODEL — What it does:                               │
│                                                      │
│  1. Reads everything (prompt + tools + history)      │
│  2. Understands your intent                          │
│     "find bugs" → need to read code → analyze it    │
│  3. Generates output:                                │
│     Either: plain text response                      │
│     Or:     tool call (structured JSON)              │
│                                                      │
│  This requires intelligence.                         │
│  Pattern matching, reasoning, language understanding.│
└──────────────────────────────────────────────────────┘
                │
                ▼
          Back to runtime
```

## 2.4 What the Runtime Does AFTER the Model Responds

```
Model output: {"tool": "fs_read", "params": {"path": "src/auth.py"}}
                │
                ▼
┌─────────────────────────────────────────────────────┐
│  KIRO RUNTIME — After model responds:                │
│                                                      │
│  1. Parse model output                               │
│     → Is it a tool call? Or plain text?              │
│  2. If tool call:                                    │
│     a. Run preToolUse hooks (can block!)             │
│     b. Check permissions (allowedTools, deniedPaths) │
│     c. Execute the tool                              │
│     d. Run postToolUse hooks                         │
│     e. Feed result back to model → go to step 1     │
│  3. If plain text:                                   │
│     a. Stream response to you                        │
│     b. Run stop hooks                                │
│     c. Save to session history                       │
│     d. Done.                                         │
└─────────────────────────────────────────────────────┘
```

## 2.5 The Complete Loop

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│   YOU   │ ──▶ │  KIRO   │ ──▶ │  MODEL  │
│         │     │(runtime)│     │ (brain) │
│         │ ◀── │         │ ◀── │         │
└─────────┘     └────┬────┘     └─────────┘
                     │
                     ▼
                ┌─────────┐
                │  TOOLS  │  ← executed by runtime,
                │         │    requested by model
                └─────────┘

Round 1: You → Kiro assembles → Model thinks → "call fs_read"
Round 2: Kiro executes fs_read → feeds result → Model thinks → "call grep"
Round 3: Kiro executes grep → feeds result → Model thinks → "Here's the answer"
Round 4: Kiro streams answer → You see it
```

## 2.6 Why This Separation Matters

**You can swap the model without changing the runtime:**
```json
{"model": "claude-sonnet"}     ← same Kiro, different brain
{"model": "claude-haiku"}      ← faster, cheaper brain
{"model": "bedrock/llama"}     ← completely different brain
```

**You can change the runtime without changing the model:**
- Kiro, Cursor, Copilot, Aider — all use Claude/GPT but with different runtimes
- Different tools, different UIs, different orchestration

**The model is stateless. The runtime manages state:**
- Model doesn't remember previous sessions — runtime loads history
- Model doesn't know which tools exist — runtime provides the list
- Model can't execute anything — runtime does the execution

---

### Try This Now

Run these two commands in Kiro and compare what happens:

**Command 1 — triggers tool calls (runtime + model working together):**
```
Read my package.json and tell me what dependencies I have
```

**Command 2 — no tools needed (model only):**
```
Explain what a REST API is in one paragraph
```

Notice the difference:
- Command 1: you will see tool calls in the output (fs_read), then the model interprets the result. Both runtime and model are working.
- Command 2: the model answers directly from its training. No tools called. The runtime just passes the message and streams the response.

This is the runtime vs brain distinction in action.

---

## Exercise 2.1: Who Does What?

Label each task as "Runtime" or "Model":

| Task | Who? |
|------|------|
| Parse your message from JSON-RPC | ? |
| Understand "find bugs in auth" means read + analyze code | ? |
| Execute `grep("TODO", "src/")` | ? |
| Decide that grep is the right tool to use | ? |
| Check if grep is in the allowedTools list | ? |
| Generate a human-readable summary of findings | ? |
| Save the conversation to disk | ? |
| Know when enough info has been gathered to stop | ? |

<details>
<summary>Answer</summary>

| Task | Who |
|------|-----|
| Parse your message from JSON-RPC | **Runtime** |
| Understand "find bugs in auth" means read + analyze code | **Model** |
| Execute `grep("TODO", "src/")` | **Runtime** |
| Decide that grep is the right tool to use | **Model** |
| Check if grep is in the allowedTools list | **Runtime** |
| Generate a human-readable summary of findings | **Model** |
| Save the conversation to disk | **Runtime** |
| Know when enough info has been gathered to stop | **Model** |

</details>

---

## Exercise 2.2: What Breaks?

What happens in each scenario?

1. **Model is removed** (runtime only) — can Kiro still work?
2. **All tools are removed** (model only) — can Kiro still work?
3. **Conversation history is lost** — what happens?
4. **System prompt is empty** — what happens?

<details>
<summary>Answer</summary>

1. **No model** — Kiro can receive your message, assemble context, but has nothing to send it to. Dead. Like an operating room with no surgeon.
2. **No tools** — Kiro works but can only chat. It becomes a chatbot. The model can reason and respond but can't take any actions.
3. **History lost** — Agent forgets everything from this session. Starts fresh. Like a surgeon with amnesia mid-operation.
4. **Empty prompt** — Model still works but has no personality or instructions. Responses will be generic. Like a surgeon with no specialization.

</details>

---

## Exercise 2.3: Trace the Flow (Live Demo)

Ask Kiro this and watch the tool calls:
```
What's the largest file in the current directory?
```

Count:
- How many "rounds" (model calls) did it take?
- Which tools were called?
- At what point did the model decide it had enough info?

---

## Expected Outcomes

After completing this module and its exercises, you should be able to:
- Explain what the runtime does before the model sees anything
- Label any agent task as "runtime responsibility" or "model responsibility"
- Predict what breaks when you remove the model, tools, history, or prompt
- Understand why the model is stateless and the runtime manages state

---

## Check Your Understanding

1. What does the runtime do that the model can't?
2. What does the model do that the runtime can't?
3. Why is the model "stateless"?
4. Can you swap the model without changing the agent config? How?

---

## Next → [Module 3: Tools — Giving AI Hands](../module-03/README.md)
