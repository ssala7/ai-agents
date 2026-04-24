# Deploy an AI Agent to AWS with Amazon Bedrock AgentCore

End-to-end guide: from zero to a live, serverless agent endpoint on AWS.

---

## What You're Building

```
Your Code (my_agent.py)
        │
        ▼
┌─────────────────────────────────────────────────────┐
│           Amazon Bedrock AgentCore Runtime           │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │  Your Agent (containerized, auto-scaled)     │   │
│  │  • get_weather tool                          │   │
│  │  • calculate tool                            │   │
│  │  • get_current_time tool                     │   │
│  └──────────────────┬───────────────────────────┘   │
│                     │ calls                          │
│                     ▼                                │
│  ┌──────────────────────────────────────────────┐   │
│  │  Amazon Bedrock (Nova Lite model)            │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  + CloudWatch Logs  + X-Ray Traces  + ECR Image      │
└─────────────────────────────────────────────────────┘
        │
        ▼
  HTTPS endpoint  ←  invoke from anywhere
```

**AgentCore handles:** containerization, scaling, session isolation, observability, IAM, ECR.  
**You handle:** agent logic, tools, system prompt.

---

## Prerequisites

Before starting, make sure you have:

| Requirement | Check | Install |
|-------------|-------|---------|
| Python 3.11+ | `python3 --version` | [python.org](https://python.org) |
| AWS CLI v2 | `aws --version` | [docs.aws.amazon.com/cli](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| Docker Desktop | `docker --version` | [docker.com](https://docker.com) |
| AWS account | — | [aws.amazon.com](https://aws.amazon.com) |
| Bedrock model access | AWS Console → Bedrock → Model access | See Step 0 below |

---

## Step 0 — Enable Bedrock Model Access

AgentCore uses Bedrock to run the model. You must explicitly enable access.

1. Open [AWS Console → Amazon Bedrock → Model access](https://console.aws.amazon.com/bedrock/home#/modelaccess)
2. Click **Manage model access**
3. Find **Amazon Nova Lite** (or any model you want to use)
4. Check the box → **Save changes**
5. Wait ~1 minute for status to show **Access granted**

> If you skip this step, the agent will fail with a `AccessDeniedException` when it tries to call the model.

---

## Step 1 — Configure AWS CLI

If you haven't already:

```bash
aws configure
```

Enter:
- AWS Access Key ID
- AWS Secret Access Key
- Default region: `us-east-1` (AgentCore is available in us-east-1, us-west-2, ap-southeast-2, eu-central-1)
- Default output format: `json`

Verify it works:
```bash
aws sts get-caller-identity
```

Expected output:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

---

## Step 2 — Clone the Repo and Navigate to the Project

```bash
git clone git@github.com:ssala7/ai-agents.git
cd ai-agents/agentcore-deploy
```

Project structure:
```
agentcore-deploy/
├── my_agent.py              ← Agent code (entry point)
├── requirements.txt         ← Python dependencies
├── scripts/
│   ├── 01_configure.sh      ← One-time setup
│   ├── 02_launch_local.sh   ← Local testing
│   └── 03_deploy_cloud.sh   ← Cloud deployment
├── iam/
│   └── execution-role-policy.json  ← IAM permissions reference
└── docs/
    └── DEPLOYMENT_GUIDE.md  ← You are here
```

---

## Step 3 — Configure the Project (Run Once)

```bash
chmod +x scripts/*.sh
./scripts/01_configure.sh
```

**What happens:**

1. Creates a Python virtual environment at `.venv/`
2. Installs `strands-agents`, `bedrock-agentcore`, and `bedrock-agentcore-starter-toolkit`
3. Runs `agentcore configure --entrypoint my_agent.py`

**During `agentcore configure` you'll be prompted:**

```
? Create IAM execution role? [Y/n]  → press Enter (auto-creates)
? ECR repository name? [agentcore-my-agent]  → press Enter (auto-creates)
? Dependency file? [requirements.txt]  → press Enter
? Enable observability? [Y/n]  → press Enter (recommended)
```

**What gets created in AWS:**
- IAM role: `agentcore-execution-role` (with Bedrock + ECR + CloudWatch permissions)
- ECR repository: `agentcore-my-agent` (stores your container image)
- Local config file: `.agentcore/config.json`

**Verify the config was created:**
```bash
cat .agentcore/config.json
```

---

## Step 4 — Test Locally

```bash
./scripts/02_launch_local.sh
```

**What happens:**

1. Starts the agent in a local Docker container (same environment as cloud)
2. Runs 4 test invocations:
   - Greeting
   - Weather tool
   - Calculator tool
   - Time tool

**Expected output for weather test:**
```json
{"city": "London", "temp": "15°C", "condition": "Cloudy"}
```

**If Docker isn't running:**
```
Error: Cannot connect to the Docker daemon
```
→ Start Docker Desktop and retry.

**Manual invocation (while local server is running):**
```bash
source .venv/bin/activate
agentcore invoke --local '{"prompt": "What is 99 * 99?"}'
```

---

## Step 5 — Deploy to AWS

```bash
./scripts/03_deploy_cloud.sh
```

**What happens (takes 3–8 minutes):**

```
1. Build container image from your code + requirements.txt
        ↓
2. Push image to ECR repository
        ↓
3. AgentCore creates a Runtime endpoint (serverless, auto-scaled)
        ↓
4. Script polls until status = READY
        ↓
5. Runs live test invocations against the cloud endpoint
```

**Monitor progress manually:**
```bash
agentcore status
```

Output when ready:
```
Status: READY
Endpoint: https://xxxx.agentcore.us-east-1.amazonaws.com
```

**Invoke the live endpoint:**
```bash
agentcore invoke '{"prompt": "What is the weather in Bangalore?"}'
agentcore invoke '{"prompt": "Calculate the square root of 144"}'
agentcore invoke '{"prompt": "What time is it?"}'
```

---

## Step 6 — Enable Observability (Optional but Recommended)

AgentCore sends traces to X-Ray and logs to CloudWatch. Enable trace delivery:

```bash
# Route X-Ray traces to CloudWatch Logs
aws xray update-trace-segment-destination --destination CloudWatchLogs

# Set 1% sampling rate (cost-effective for production)
aws xray update-indexing-rule \
  --name "Default" \
  --rule '{"Probabilistic": {"DesiredSamplingPercentage": 1}}'

# Verify
aws xray get-trace-segment-destination
aws xray get-indexing-rules
```

**View logs in CloudWatch:**
```
AWS Console → CloudWatch → Log groups → /aws/bedrock-agentcore/
```

**View traces:**
```
AWS Console → X-Ray → Traces
```

---

## IAM Permissions Reference

The execution role needs these permissions. The `agentcore configure` command creates this automatically, but if you need to create it manually, use `iam/execution-role-policy.json`:

```bash
# Create the policy
aws iam create-policy \
  --policy-name AgentCoreExecutionPolicy \
  --policy-document file://iam/execution-role-policy.json

# Attach to the execution role
aws iam attach-role-policy \
  --role-name agentcore-execution-role \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AgentCoreExecutionPolicy
```

**Permissions breakdown:**

| Permission | Why needed |
|-----------|-----------|
| `bedrock:InvokeModel` | Agent calls the Nova Lite model |
| `bedrock-agentcore:*` | Create/manage the Runtime endpoint |
| `ecr:GetDownloadUrlForLayer` | Pull container image at runtime |
| `logs:PutLogEvents` | Write agent logs to CloudWatch |
| `xray:PutTraceSegments` | Send traces for observability |

---

## Customizing the Agent

### Change the model

In `my_agent.py`, update the `model` parameter:

```python
agent = Agent(
    model="us.anthropic.claude-3-5-haiku-20241022-v1:0",  # Claude Haiku
    # or
    model="us.amazon.nova-pro-v1:0",                       # Nova Pro
    ...
)
```

Available Bedrock model IDs: [docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html](https://docs.aws.amazon.com/bedrock/latest/userguide/model-ids.html)

### Add a new tool

```python
@tool
def search_web(query: str) -> str:
    """Search the web for information about a topic."""
    # your implementation here
    return json.dumps({"results": [...]})

# Add to the agent's tools list:
agent = Agent(
    model="us.amazon.nova-lite-v1:0",
    tools=[get_weather, calculate, get_current_time, search_web],  # ← add here
    ...
)
```

Then redeploy:
```bash
./scripts/03_deploy_cloud.sh
```

### Change the system prompt

Edit `SYSTEM_PROMPT` in `my_agent.py`:

```python
SYSTEM_PROMPT = """
You are a specialized financial assistant.
Always provide disclaimers when giving financial advice.
Use the calculate tool for any numerical computations.
"""
```

---

## Troubleshooting

### `AccessDeniedException` when invoking model
→ Enable model access in Bedrock Console (Step 0)

### `Cannot connect to Docker daemon`
→ Start Docker Desktop

### `agentcore: command not found`
→ Activate the virtual environment: `source .venv/bin/activate`

### `ECR push failed: no basic auth credentials`
→ Re-authenticate Docker to ECR:
```bash
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

### Endpoint stuck in `CREATING` state
→ Check CloudWatch logs for errors:
```bash
aws logs tail /aws/bedrock-agentcore/ --follow
```

### `agentcore configure` fails with permission error
→ Your AWS user needs these IAM permissions:
- `iam:CreateRole`, `iam:AttachRolePolicy`
- `ecr:CreateRepository`
- `bedrock-agentcore:*`

---

## Cleanup (Avoid Ongoing Charges)

When you're done:

```bash
# Delete the AgentCore Runtime endpoint
agentcore delete

# Delete the ECR repository (and all images)
aws ecr delete-repository \
  --repository-name agentcore-my-agent \
  --force \
  --region us-east-1

# Delete the IAM role (optional)
aws iam detach-role-policy \
  --role-name agentcore-execution-role \
  --policy-arn arn:aws:iam::<ACCOUNT_ID>:policy/AgentCoreExecutionPolicy
aws iam delete-role --role-name agentcore-execution-role
```

---

## Invocation Patterns

Once your agent is deployed (or even locally), there are three ways to run it depending on your use case.

### 1. Local CLI (Interactive)

Chat with the agent directly from your terminal:

```python
# cli.py
from my_agent import agent

while True:
    prompt = input("You: ").strip()
    if prompt in ("exit", "quit"):
        break
    response = agent(prompt)
    print("Agent:", response.message["content"][0]["text"])
```

```bash
python cli.py
# You: What is the weather in Bangalore?
# Agent: The weather in Bangalore is 28°C and Partly cloudy.
```

> The `BedrockAgentCoreApp` wrapper is only needed for cloud deployment. The `agent` object works standalone.

---

### 2. Autonomous Runs (Batch / Scheduled)

Agent runs a fixed set of tasks with no human input. Good for cron jobs and pipelines:

```python
# autonomous.py
from my_agent import agent

TASKS = [
    "Get weather for London and Bangalore",
    "Calculate 999 * 42",
    "What is the current UTC time?",
]

for task in TASKS:
    print(f"\n>> {task}")
    response = agent(task)
    print(response.message["content"][0]["text"])
```

Schedule it with cron:
```bash
# crontab -e
*/30 * * * * python /path/to/autonomous.py >> /var/log/agent.log 2>&1
```

---

### 3. Event-Driven Loop (Reacts to External Triggers)

Agent polls for events and reacts. Swap the queue source for SQS, webhooks, file watchers, etc.:

```python
# event_loop.py
import time, json
from queue import Queue
from my_agent import agent

event_queue = Queue()

def handle_event(event):
    if event["type"] == "weather_check":
        prompt = f"Get weather for {event['city']}"
    elif event["type"] == "calculation":
        prompt = f"Calculate {event['expr']}"
    else:
        prompt = "What is the current time?"

    response = agent(prompt)
    print(f"[{event['type']}]", response.message["content"][0]["text"])

print("Listening for events...")
while True:
    if not event_queue.empty():
        handle_event(event_queue.get())
    else:
        time.sleep(1)
```

**Using AWS SQS as the event source:**
```python
import boto3, json

sqs = boto3.client("sqs")
QUEUE_URL = "<your-queue-url>"

while True:
    msgs = sqs.receive_message(QueueUrl=QUEUE_URL, WaitTimeSeconds=10)
    for msg in msgs.get("Messages", []):
        handle_event(json.loads(msg["Body"]))
        sqs.delete_message(QueueUrl=QUEUE_URL, ReceiptHandle=msg["ReceiptHandle"])
```

---

### Pattern Summary

| Pattern | Use when | Entry point |
|---------|----------|-------------|
| Local CLI | Interactive chat / development | `cli.py` |
| Autonomous | Cron jobs, batch tasks, pipelines | `autonomous.py` |
| Event-driven loop | React to SQS, webhooks, file changes | `event_loop.py` |

All three reuse the same `agent` object from `my_agent.py` — no changes to core agent code needed.

---

## What's Next

Once your agent is live, you can extend it with other AgentCore services:

| Service | What it adds | How to add |
|---------|-------------|-----------|
| **AgentCore Memory** | Session + long-term memory across invocations | `from bedrock_agentcore.memory import MemoryClient` |
| **AgentCore Gateway** | Turn Lambda functions / APIs into MCP tools | AWS Console → AgentCore → Gateway |
| **AgentCore Identity** | OAuth / API key management for tools | `from bedrock_agentcore.services.identity import IdentityClient` |
| **AgentCore Browser** | Give agent a managed web browser | AgentCore SDK browser tool |
| **AgentCore Code Interpreter** | Safe code execution sandbox | AgentCore SDK code interpreter tool |

Full docs: [docs.aws.amazon.com/bedrock-agentcore](https://docs.aws.amazon.com/bedrock-agentcore/latest/devguide/)
