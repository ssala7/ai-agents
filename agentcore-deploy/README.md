# AgentCore Deploy — AI Agent on AWS

A complete agent with 3 tools (weather, calculator, time) ready to run locally or deploy to AWS Bedrock AgentCore.

---

## Quick Start (Local, No Docker)

Just want to test the agent? No AWS deployment needed:

```bash
cd agentcore-deploy
python3 -m venv .venv
source .venv/bin/activate
pip install strands-agents

python3 -c "
from my_agent import agent
print(agent('What is the weather in London?').message['content'][0]['text'])
"
```

That's it. The agent runs locally using your AWS credentials for Bedrock model access.

### Prerequisites for local-only

- Python 3.11+
- AWS credentials configured (`aws configure`)
- Bedrock model access enabled (AWS Console → Bedrock → Model access)

---

## Deploy to AWS (Full AgentCore Runtime)

Deploy as a serverless, auto-scaled endpoint on AWS:

```bash
./scripts/01_configure.sh    # one-time: venv + IAM role + ECR repo
./scripts/02_launch_local.sh # test in local Docker container
./scripts/03_deploy_cloud.sh # build, push, deploy to AWS
```

### Prerequisites for cloud deploy

- Everything above, plus:
- Docker Desktop running
- AWS account with AgentCore permissions

### What the scripts do

| Script | Purpose | Needs Docker? |
|--------|---------|---------------|
| `01_configure.sh` | Creates venv, installs deps, sets up IAM role + ECR repo | No |
| `02_launch_local.sh` | Runs agent in a local container, tests all tools | Yes |
| `03_deploy_cloud.sh` | Builds container, pushes to ECR, creates live endpoint | Yes |

---

## Project Structure

```
agentcore-deploy/
├── my_agent.py              ← Agent code (3 tools + system prompt)
├── requirements.txt         ← Python dependencies (pinned)
├── scripts/
│   ├── 01_configure.sh      ← One-time AWS setup
│   ├── 02_launch_local.sh   ← Local Docker test
│   └── 03_deploy_cloud.sh   ← Cloud deployment
├── iam/
│   └── execution-role-policy.json  ← IAM permissions reference
└── docs/
    └── DEPLOYMENT_GUIDE.md  ← Full step-by-step walkthrough
```

---

## Changing the Model

Edit `my_agent.py`:

```python
model="anthropic.claude-3-haiku-20240307-v1:0",  # works in most regions
model="us.amazon.nova-lite-v1:0",                 # US regions only
model="amazon.nova-lite-v1:0",                    # if available in your region
```

---

## Full Guide

See [docs/DEPLOYMENT_GUIDE.md](docs/DEPLOYMENT_GUIDE.md) for the complete walkthrough including observability, troubleshooting, cleanup, and invocation patterns.
