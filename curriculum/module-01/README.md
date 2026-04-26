# Module 1: What is an AI Agent?

> **Key Question:** How is an agent different from a chatbot?

---

## 1.1 The Simple Answer

A **chatbot** can only talk. An **agent** can talk AND do things.

```
Chatbot:
  You: "Delete the temp files"
  Bot: "To delete temp files, run: rm -rf /tmp/*"   ← gives instructions

Agent:
  You: "Delete the temp files"
  Agent: [executes: rm -rf /tmp/*]                   ← actually does it
  Agent: "Done. Deleted 23 temp files."
```

## 1.2 The Three Parts of an Agent

Every AI agent has three components:

```
┌─────────────────────────────────────────────┐
│                 AI AGENT                      │
│                                              │
│  ┌──────────┐  ┌─────────┐  ┌────────────┐ │
│  │  Brain   │  │  Tools  │  │  Memory    │ │
│  │ (Model)  │  │ (Actions)│  │ (Context)  │ │
│  └──────────┘  └─────────┘  └────────────┘ │
│                                              │
│  Understands    Can read      Remembers      │
│  language,      files, run    conversation,  │
│  reasons,       commands,     past actions,  │
│  decides        call APIs     user prefs     │
└─────────────────────────────────────────────┘
```

**Analogy: A new employee**
- Brain = their education and intelligence
- Tools = access to email, Slack, code editor, databases
- Memory = notes from meetings, project context

Without tools, they can only talk. Without memory, they forget everything between conversations. Without a brain, nothing works.

## 1.3 Agent vs Chatbot vs Automation

| | Chatbot | Automation (script) | Agent |
|---|---|---|---|
| Understands language? | Yes | No | Yes |
| Takes actions? | No | Yes | Yes |
| Adapts to new situations? | Somewhat | No | Yes |
| Handles ambiguity? | Yes | No | Yes |
| Follows a fixed script? | Often | Always | Never |

An agent combines the language understanding of a chatbot with the action-taking of automation, plus the ability to adapt.

## 1.4 What Makes Kiro an Agent?

Kiro is an agent because it has all three parts:

```
Brain:   Claude (or other model via Bedrock)
Tools:   fs_read, fs_write, shell, grep, glob, code, use_aws, web_search...
Memory:  Conversation context + Knowledge base
```

When you say "find all TODO comments and create a summary file":
1. **Brain** understands the request and makes a plan
2. **Tools** execute: grep for TODOs → read files → write summary
3. **Memory** tracks what was found so far, what's left to do

## 1.5 The Agent Loop

Every agent runs the same fundamental loop:

```
         ┌──────────────────────┐
         │   Receive input      │ ← your message
         └──────────┬───────────┘
                    │
                    ▼
         ┌──────────────────────┐
         │   Think (model)      │ ← understand, reason, plan
         └──────────┬───────────┘
                    │
              ┌─────┴─────┐
              ▼           ▼
     ┌──────────┐  ┌───────────┐
     │ Respond  │  │ Act (tool)│
     │ (text)   │  │           │
     └──────────┘  └─────┬─────┘
                         │
                         ▼
                  ┌──────────────┐
                  │ Observe      │ ← see tool result
                  │ result       │
                  └──────┬───────┘
                         │
                         ▼
                  Back to "Think"
                  (loop until done)
```

This is called the **Think --> Act --> Observe** loop. It repeats until the agent has enough information to give you a final answer.

---

### Try This Now

Open Kiro and type this:

```
What files are in the current directory and which is the largest?
```

Watch what happens in the output. You will see:
1. The agent calls a tool (likely `glob` or `shell`) to list files
2. It calls another tool to check sizes
3. It reasons about the results
4. It gives you a plain text answer

That sequence — think, act, observe, repeat — is the agent loop running in real time. Every agent works this way.

---

## Exercise 1.1: Spot the Agent

Which of these is an agent? Why?

1. Google Search — you type a query, it returns links
2. Siri — you say "set a timer for 5 minutes", it sets a timer
3. ChatGPT (no plugins) — you ask a question, it answers from training data
4. Kiro — you say "refactor this function", it reads the file, edits it, runs tests
5. A cron job that backs up your database every night

<details>
<summary>Answer</summary>

- **Google Search** — Not an agent. It's a search engine. No reasoning, no actions beyond searching.
- **Siri** — Agent-like. Understands language + takes actions (set timer, send text). But limited reasoning.
- **ChatGPT (no plugins)** — Chatbot. Understands language but can't take actions.
- **Kiro** — Full agent. Understands language + reasons + takes actions + adapts.
- **Cron job** — Automation. Takes actions but no understanding, no adaptation.

</details>

---

## Exercise 1.2: Identify the Parts

For Kiro, identify what plays each role:

| Part | What is it in Kiro? |
|------|-------------------|
| Brain | ? |
| Tools | ? |
| Memory | ? |

<details>
<summary>Answer</summary>

| Part | What is it in Kiro |
|------|-------------------|
| Brain | Claude (LLM model, can be swapped via Bedrock) |
| Tools | fs_read, fs_write, shell, grep, glob, code, use_aws, knowledge, web_search, subagent, etc. |
| Memory | Context window (short-term, this session) + Knowledge base (long-term, across sessions) |

</details>

---

## Exercise 1.3: Try It (Live Demo)

Ask Kiro something that requires multiple steps:

```
Find all Python files in this directory, count them, and tell me which one is the largest.
```

Watch what happens:
1. It calls `glob` to find .py files
2. It calls `fs_read` or `shell` to check sizes
3. It reasons about the results
4. It gives you a final answer

That's the Think → Act → Observe loop in action.

---

## Expected Outcomes

After completing this module and its exercises, you should be able to:
- Distinguish between a chatbot, an automation script, and an agent
- Name the three core parts of any agent (brain, tools, memory)
- Describe the Think-Act-Observe loop and recognize it in Kiro's output
- Identify which real-world systems qualify as agents and why

---

## Check Your Understanding

1. What's the difference between a chatbot and an agent?
2. What are the three core parts of any agent?
3. What is the Think → Act → Observe loop?
4. Can an agent work without a model? Why or why not?

---

## Next → [Module 2: The Runtime vs The Brain](../module-02/README.md)
