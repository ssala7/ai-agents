# AI Agents — From Fundamentals to Production

A structured, hands-on curriculum for understanding, building, and deploying AI agents. Covers agent architecture, tool systems, multi-agent coordination, and production deployment on AWS.

## What You Will Build

By the end of this curriculum, you will have:

- Understood the internal architecture of AI agents (brain, tools, memory, protocols)
- Built a custom AI tool (MCP server) from scratch in Python
- Created a specialized agent configuration and wired it to your tools
- Tested the full agent loop: your input -> model reasoning -> tool execution -> result
- Understood how multi-agent DAG pipelines coordinate parallel work
- Deployed a production agent to AWS Bedrock AgentCore with observability

---

## Table of Contents

- [Who Is This For](#who-is-this-for)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Learning Tracks](#learning-tracks)
  - [Basics — What Are AI Agents?](#basics--what-are-ai-agents)
  - [Intermediate — Build and Extend Agents](#intermediate--build-and-extend-agents)
  - [Advanced — Multi-Agent Systems and Production Deployment](#advanced--multi-agent-systems-and-production-deployment)
- [Repository Structure](#repository-structure)
- [Quick Start](#quick-start)
- [Reference Materials](#reference-materials)
- [Contributing](#contributing)

---

## Who Is This For

- Developers who want to understand how AI agents work internally
- Team leads evaluating agent frameworks and architectures
- Engineers building agent-powered products
- Anyone curious about how tools like Kiro, Cursor, and Copilot work under the hood

No AI/ML background required. Basic programming and terminal familiarity is enough.

---

## Prerequisites

| Requirement | Check | Install |
|-------------|-------|---------|
| Python 3.11+ | `python3 --version` | [python.org](https://python.org) |
| Kiro CLI | `kiro-cli --version` | See Installation below |
| AWS CLI v2 (for Advanced track) | `aws --version` | [AWS CLI install guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| Docker (for Advanced track) | `docker --version` | [docker.com](https://docker.com) |
| AWS account with Bedrock access (for Advanced track) | AWS Console | [aws.amazon.com](https://aws.amazon.com) |

---

## Installation

### Install Kiro CLI

macOS:
```bash
brew install kiro-cli
```

Linux:
```bash
curl -fsSL https://kiro.dev/install.sh | bash
```

Verify:
```bash
kiro-cli --version
```

Start a chat session:
```bash
kiro-cli chat
```

### Clone This Repository

```bash
git clone https://github.com/ssala7/ai-agents.git
cd ai-agents
```

### Enable Knowledge Base (optional, for Module 6)

```bash
kiro-cli settings chat.enableKnowledge true
```

---

## Learning Tracks

The curriculum is organized into three tracks. Each builds on the previous one.

```
BASICS (Modules 1-4)          INTERMEDIATE (Modules 5-8)       ADVANCED
Concepts and mental models     Hands-on building                Production deployment
~2 hours                       ~3 hours                         ~2 hours

[1] What is an Agent?     -->  [5] Protocols: ACP & JSON-RPC   --> AgentCore Deploy
[2] Runtime vs Brain      -->  [6] Sessions & Memory               (AWS Bedrock)
[3] Tools                 -->  [7] Multi-Agent: DAGs
[4] How AI Decides        -->  [8] Build Your Own (Lab)
```

---

### Basics — What Are AI Agents?

Conceptual foundations. No coding required. Understand the architecture before building.

| Module | Topic | Key Question | Duration |
|--------|-------|-------------|----------|
| 1 | [What is an AI Agent?](curriculum/module-01/README.md) | How is an agent different from a chatbot? | 30 min |
| 2 | [The Runtime vs The Brain](curriculum/module-02/README.md) | What does the runtime do vs the model? | 30 min |
| 3 | [Tools — Giving AI Hands](curriculum/module-03/README.md) | How does an agent interact with the real world? | 60 min |
| 4 | [How AI Decides What To Do](curriculum/module-04/README.md) | How does the model pick which tool to call? | 30 min |

After completing Basics, you will understand:
- The three parts of any agent (brain, tools, memory)
- Why the runtime and model are separate concerns
- How tool descriptions drive the AI's decision-making
- The Think-Act-Observe loop that powers all agents

---

### Intermediate — Build and Extend Agents

Hands-on modules. You will write code, test tools, and build a custom agent.

| Module | Topic | Key Question | Duration |
|--------|-------|-------------|----------|
| 5 | [Protocols: ACP & JSON-RPC](curriculum/module-05/README.md) | How do components talk to each other? | 45 min |
| 6 | [Sessions & Memory](curriculum/module-06/README.md) | How does an agent remember things? | 30 min |
| 7 | [Multi-Agent: DAGs & Subagents](curriculum/module-07/README.md) | How do multiple agents coordinate? | 45 min |
| 8 | [Build Your Own — Hands-On Lab](curriculum/module-08/README.md) | Can I build all of this myself? | 60 min |

After completing Intermediate, you will have:
- Built a custom MCP tool server in Python
- Created an agent configuration that uses your custom tools
- Tested the full flow: you -> agent -> tool -> result
- Understood how multi-agent DAG pipelines work

---

### Advanced — Multi-Agent Systems and Production Deployment

Deploy a real agent to AWS using Amazon Bedrock AgentCore.

| Topic | What You Build | Duration |
|-------|---------------|----------|
| [AgentCore Deployment Guide](agentcore-deploy/docs/DEPLOYMENT_GUIDE.md) | Live agent endpoint on AWS | 60-90 min |

What the Advanced track covers:
- Containerized agent deployment with AgentCore Runtime
- Strands Agents SDK with custom tools (weather, calculator, time)
- IAM roles, ECR image management, CloudWatch observability
- Three invocation patterns: interactive CLI, batch/scheduled, event-driven
- Production concerns: scaling, monitoring, cleanup

```
agentcore-deploy/
├── my_agent.py              -- Agent code (Strands Agents + 3 tools)
├── requirements.txt         -- Python dependencies
├── scripts/
│   ├── 01_configure.sh      -- One-time setup (venv + IAM + ECR)
│   ├── 02_launch_local.sh   -- Test locally in Docker
│   └── 03_deploy_cloud.sh   -- Build, push, deploy to AWS
├── iam/
│   └── execution-role-policy.json
└── docs/
    └── DEPLOYMENT_GUIDE.md  -- Full step-by-step guide
```

The three-command deploy flow:
```bash
./scripts/01_configure.sh    # setup (run once)
./scripts/02_launch_local.sh # test locally
./scripts/03_deploy_cloud.sh # deploy to AWS
```

---

## Repository Structure

```
ai-agents/
├── README.md                          -- You are here
│
├── curriculum/                        -- 8-module structured course
│   ├── CURRICULUM.md                  -- Course overview and teaching guide
│   ├── BRIDGE.md                      -- Transition from Intermediate to Advanced
│   ├── TROUBLESHOOTING.md             -- Common problems and fixes
│   ├── module-01/                     -- Basics: What is an Agent?
│   ├── module-02/                     -- Basics: Runtime vs Brain
│   ├── module-03/                     -- Basics: Tools
│   ├── module-04/                     -- Basics: How AI Decides
│   ├── module-05/                     -- Intermediate: Protocols
│   ├── module-06/                     -- Intermediate: Sessions & Memory
│   ├── module-07/                     -- Intermediate: Multi-Agent DAGs
│   └── module-08/                     -- Intermediate: Hands-On Lab
│
├── hands-on/                          -- Working code for the lab
│   ├── WALKTHROUGH.md                 -- Step-by-step build guide
│   ├── mcp-server/server.py           -- Custom MCP tool server (Python)
│   └── agent/demo-agent.json          -- Agent config wired to custom tools
│
├── agentcore-deploy/                  -- Advanced: AWS production deployment
│   ├── my_agent.py                    -- Agent code (Strands Agents SDK)
│   ├── requirements.txt
│   ├── scripts/                       -- Automated setup, test, deploy
│   ├── iam/                           -- IAM policy reference
│   └── docs/DEPLOYMENT_GUIDE.md       -- Full deployment walkthrough
│
├── examples/                          -- Subagent pipeline configurations
│   ├── 01-parallel-research.json      -- All stages run in parallel
│   ├── 02-sequential-pipeline.json    -- Research -> Implement -> Review
│   └── 03-fan-out-fan-in.json         -- Parallel work -> single summary
│
├── diagrams/                          -- Architecture and flow diagrams
│   ├── dag-examples.md                -- Visual DAG patterns
│   └── end-to-end-flow.md            -- Full request lifecycle
│
├── guides/                            -- Deep-dive reference guides
│   └── agent-configuration.md         -- Agent config from zero to full
│
└── cheatsheets/                       -- Quick reference cards
    ├── session-commands.md            -- Session management API reference
    └── kiro-commands.md               -- Full Kiro CLI command reference
```

---

## Quick Start

### Option 1: Start with the concepts (recommended)

Read [Module 1: What is an AI Agent?](curriculum/module-01/README.md) and work through the modules in order.

### Option 2: Jump to hands-on

If you already understand agent basics, go directly to [Module 8: Build Your Own](curriculum/module-08/README.md) or the [Hands-On Walkthrough](hands-on/WALKTHROUGH.md).

### Option 3: Deploy to AWS

If you want to deploy immediately, go to the [AgentCore Deployment Guide](agentcore-deploy/docs/DEPLOYMENT_GUIDE.md).

### Option 4: Try things in Kiro right now

```bash
kiro-cli chat
```

Then try:
```
/spawn Research best practices for error handling in Python
```
Press `Ctrl+G` to watch the background session.

---

## Reference Materials

| Resource | What it covers |
|----------|---------------|
| [Agent Configuration Guide](guides/agent-configuration.md) | Building agent configs layer by layer |
| [DAG Examples](diagrams/dag-examples.md) | Visual patterns for multi-agent pipelines |
| [End-to-End Flow](diagrams/end-to-end-flow.md) | Full request lifecycle from input to response |
| [Session Commands Cheatsheet](cheatsheets/session-commands.md) | Session management API reference |
| [Kiro Commands Reference](cheatsheets/kiro-commands.md) | Every slash command with examples |
| [Pipeline Examples](examples/) | JSON configs for parallel, sequential, fan-out pipelines |
| [Bridge: Intermediate to Advanced](curriculum/BRIDGE.md) | What changes when you go from local to production |
| [Troubleshooting](curriculum/TROUBLESHOOTING.md) | Common problems and fixes across all modules |

---

## Teaching Formats

This curriculum works for:

| Format | Approach |
|--------|----------|
| 1-day workshop | All 8 modules + deployment demo, ~6 hours with breaks |
| 4-week course | 2 modules per week, exercises as homework |
| Self-paced | Read in order, do every exercise, Module 8 is the capstone |
| Lunch and learn | Pick any single module as a standalone session |

See [curriculum/CURRICULUM.md](curriculum/CURRICULUM.md) for instructor notes and teaching tips.

---

## Contributing

Contributions welcome. If you find errors, want to add examples, or improve explanations:

1. Fork the repository
2. Create a branch for your changes
3. Submit a pull request with a clear description

Keep the style consistent: plain language, ASCII diagrams, exercises with collapsible answers, no emojis in technical content.
