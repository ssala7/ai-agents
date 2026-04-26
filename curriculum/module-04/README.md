# Module 4: How AI Decides What To Do

> **Key Question:** How does the model pick which tool to call?

---

## 4.1 There Is No Decision Engine

This is the most misunderstood part. The AI doesn't have if-else logic or a decision tree. It's a **language model** — it predicts the most likely next text given everything it's seen.

```
NOT how it works:
  if "read file" in user_input:
      call fs_read()
  elif "search" in user_input:
      call grep()

HOW it actually works:
  Model sees: [system prompt + tool definitions + history + your message]
  Model generates: the most probable next text
  That text happens to be a tool call (or a plain response)
```

## 4.2 What the Model Actually Sees

When you type "count words in my readme", the model's input looks like:

```
┌─────────────────────────────────────────────────────────┐
│ SYSTEM: You are Kiro, an AI assistant...                 │
│                                                          │
│ AVAILABLE TOOLS:                                         │
│ ┌──────────────────────────────────────────────────────┐ │
│ │ fs_read: Read files. Params: path, mode              │ │
│ │ grep: Search text in files. Params: pattern, path    │ │
│ │ shell: Execute bash commands. Params: command         │ │
│ │ glob: Find files by pattern. Params: pattern          │ │
│ │ word_count: Count words/lines/chars. Params: text     │ │
│ └──────────────────────────────────────────────────────┘ │
│                                                          │
│ CONVERSATION:                                            │
│ User: count words in my readme                           │
│                                                          │
│ Assistant: ???  ← model generates this                   │
└─────────────────────────────────────────────────────────┘
```

The model reads the tool descriptions like a **menu** and picks what matches your intent.

## 4.3 The Matching Process

It's probabilistic pattern matching, not rule-based:

```
Your words:        Tool descriptions:                  Match strength:
─────────────      ──────────────────                  ───────────────
"count words"  →   fs_read: "Read files"               Weak
"count words"  →   grep: "Search text in files"        Weak
"count words"  →   shell: "Execute bash commands"      Medium (wc -w)
"count words"  →   word_count: "Count words/lines"     Strong ✓
"in my readme" →   fs_read: "Read files"               Strong ✓

Model decides: first fs_read("README.md"), then word_count(result)
               OR: shell("wc -w README.md")
```

The model was trained on millions of examples where humans used tools. It learned patterns like:
- "read a file" → fs_read
- "search for text" → grep
- "run a command" → shell
- "count words" → wc or word_count

## 4.4 Why Tool Descriptions Matter So Much

Compare these two descriptions for the same tool:

```
Bad:  "process_data" — "Processes data"
Good: "word_count"   — "Count the number of words, lines, and characters in the given text"
```

With the bad description, the model has no idea when to use it. With the good one, it immediately matches "count words in my readme" to this tool.

**The description is the tool's advertisement to the AI.**

---

### Try This Now

Ask Kiro the same question two different ways and see if it picks the same tool:

```
How many lines are in my README?
```

```
Count the lines in README.md
```

Both should trigger a tool call, but the model might pick different tools (shell with `wc -l`, or fs_read then count, or grep with `-c`). The model is probabilistic — it picks the most likely tool based on pattern matching, not a fixed rule. Run both and compare.

Then try this — a request where no tool is needed:

```
What is the difference between TCP and UDP?
```

The model answers from its training data. No tool call. It knows when tools are unnecessary.

---

## 4.5 The Generation Format

When the model decides to use a tool, it generates a structured output:

```
Model generates (plain text response):
  "Your README has about 500 words."     ← just text, no tool call

Model generates (tool call):
  {
    "tool": "fs_read",                   ← which tool
    "params": {                          ← with what parameters
      "path": "README.md",
      "mode": "Line"
    }
  }
```

The runtime detects the format:
- Looks like a tool call? → Execute it, feed result back
- Looks like plain text? → Show it to the user

## 4.6 The Multi-Turn Loop

Most tasks need multiple tool calls. The model keeps going until it has enough info:

```
Round 1:
  Input:  "find the largest Python file"
  Output: tool_call(glob, pattern="**/*.py")
  → Runtime executes, gets: [app.py, utils.py, test_app.py]

Round 2:
  Input:  [previous context + glob results]
  Output: tool_call(shell, command="wc -c app.py utils.py test_app.py")
  → Runtime executes, gets: sizes

Round 3:
  Input:  [previous context + sizes]
  Output: "The largest Python file is app.py at 2,847 bytes."
  → Runtime: no tool call → show to user. Done.
```

**How does the model know when to stop?** It doesn't have a rule. It's trained to recognize when it has sufficient information to answer. If it has file sizes, it can answer "which is largest" — so it generates text instead of another tool call.

## 4.7 When It Goes Wrong

Since it's probabilistic, the model sometimes:

| Problem | Example | Why |
|---------|---------|-----|
| Wrong tool | Uses `grep` when `glob` is better | Descriptions overlap |
| Wrong params | `fs_read("readme.txt")` when file is `README.md` | Guessing the filename |
| Skips tool call | "Your readme probably has ~200 words" | Answers from training data instead of checking |
| Too many calls | Reads every file one by one | Doesn't think of a more efficient approach |
| Hallucinated tool | Tries to call `count_words` (doesn't exist) | Confused by similar names |

These aren't bugs — they're the nature of probabilistic systems. Better tool descriptions, clearer prompts, and better models reduce these errors.

## 4.8 How to Influence the Decision

You can steer the model's tool choices:

**1. System prompt (agent config):**
```json
{"prompt": "Always use grep for searching. Prefer shell commands over multiple tool calls."}
```

**2. Tool descriptions (MCP server):**
```json
{"description": "Use this ONLY for counting words. Do NOT use for file reading."}
```

**3. Your message:**
```
"Use grep to find all TODO comments"     ← explicit tool mention
vs
"Find all TODO comments"                  ← model picks the tool
```

---

## Exercise 4.1: Predict the Tool

For each request, predict which tool the model would pick and why:

1. "What's in my .env file?"
2. "How many TypeScript files do I have?"
3. "Is there a memory leak in my code?"
4. "Deploy this to staging"
5. "What did we discuss yesterday?"

<details>
<summary>Answer</summary>

1. `fs_read(".env")` — "what's in" = read the file
2. `glob("**/*.ts")` then count — or `shell("find . -name '*.ts' | wc -l")`
3. `fs_read` or `grep` to read code, then **model reasons** about it — no "memory leak detector" tool
4. `execute_bash` — but model might ask for clarification (what command? what environment?)
5. `knowledge.search` if enabled, otherwise model says "I don't have access to previous sessions"

Key insight: #3 shows the model does MORE than just pick tools. It reads code and **reasons** about it. The intelligence is in the model, not the tools.

</details>

---

## Exercise 4.2: Bad vs Good Descriptions

Which description would work better? Why?

**Tool A:**
```json
{"name": "do_thing", "description": "Does a thing with data"}
```

**Tool B:**
```json
{"name": "csv_to_json", "description": "Convert a CSV file to JSON format. Input: file path to a .csv file. Output: JSON string."}
```

<details>
<summary>Answer</summary>

Tool B is far better because:
- Name is descriptive (`csv_to_json` vs `do_thing`)
- Description says exactly WHAT it does, WHAT input it needs, WHAT output it produces
- The model can match "convert this CSV to JSON" directly to this tool
- Tool A would almost never be selected because the model can't tell when it's relevant

</details>

---

## Exercise 4.3: Trace a Real Interaction

Ask Kiro:
```
Find all files larger than 100KB in the current directory and list them sorted by size
```

Watch and note:
1. Which tools were called in which order?
2. Did the model use one tool call or multiple?
3. Did it use `shell` (one command) or `glob` + `fs_read` (multiple tools)?
4. Could it have done it differently?

---

## Expected Outcomes

After completing this module and its exercises, you should be able to:
- Explain that tool selection is probabilistic, not rule-based
- Predict which tool the model will pick for a given request
- Write a good tool description that the model can match against
- Describe the multi-turn loop and how the model knows when to stop
- Identify common failure modes (wrong tool, hallucinated params, skipped tool call)

---

## Check Your Understanding

1. Does the AI use if-else logic to pick tools? What does it use instead?
2. Why are tool descriptions so important?
3. How does the model know when to stop calling tools?
4. What happens when the model picks the wrong tool?
5. Name three ways to influence which tool the model picks.

---

## Next → [Module 5: Protocols — ACP & JSON-RPC](../module-05/README.md)
