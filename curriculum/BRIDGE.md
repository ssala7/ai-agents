# Bridge: From Kiro Agents to Production Deployment

You have completed the Intermediate track. Here is what you know and what comes next.

---

## What You Have Learned So Far

In Modules 1-8, you worked with Kiro CLI as the agent runtime:

```
You (terminal) --> Kiro (runtime) --> Claude (model)
                       |
                       v
                  Tools (built-in + your custom MCP server)
```

Kiro handles everything: session management, tool execution, protocol handling, context assembly. The model runs remotely via an API. Your custom tools run locally via stdio.

This is great for development and personal use. But what about production?

---

## What Changes in Production

| Concern | Kiro (local) | Production (AWS) |
|---------|-------------|-----------------|
| Where does the agent run? | Your machine | AWS container (auto-scaled) |
| Who manages the runtime? | Kiro CLI | Bedrock AgentCore Runtime |
| Where does the model run? | Remote API | Bedrock (same AWS account) |
| How are tools defined? | MCP servers (JSON-RPC) | Python functions with `@tool` decorator |
| How is it invoked? | Terminal chat | HTTPS endpoint, SDK, or event triggers |
| Scaling | Single user | Auto-scaled, multi-tenant |
| Observability | Terminal output | CloudWatch Logs + X-Ray Traces |

---

## The Architecture Shift

```
LOCAL (what you built in Module 8):

  You --> Kiro --> Claude API
              |
              v
         MCP Server (stdio)
         server.py


PRODUCTION (what you will build in the Advanced track):

  Any Client --> HTTPS --> AgentCore Runtime --> Bedrock Model
                               |
                               v
                          @tool functions
                          (in your agent code)
```

The core concepts are identical:
- An agent still has a brain (model), tools, and memory
- Tools still have names, descriptions, and parameter schemas
- The model still picks tools based on descriptions
- The Think-Act-Observe loop still runs

What changes is the packaging and infrastructure, not the architecture.

---

## What You Will Build

The Advanced track uses the **Strands Agents SDK** instead of Kiro CLI. Strands is a Python framework for building standalone agents that can be deployed anywhere.

Your agent (`agentcore-deploy/my_agent.py`) has:
- A system prompt
- Three tools: `get_weather`, `calculate`, `get_current_time`
- A Bedrock model (Amazon Nova Lite)
- An entry point that AgentCore calls on each invocation

The deploy flow:
```
01_configure.sh   --> creates IAM role + ECR repo + virtual environment
02_launch_local.sh --> runs agent in local Docker container, runs test invocations
03_deploy_cloud.sh --> builds container, pushes to ECR, creates live endpoint
```

---

## Prerequisites for the Advanced Track

Before starting, verify you have:

```bash
python3 --version    # 3.11+
aws --version        # AWS CLI v2
docker --version     # Docker Desktop running
aws sts get-caller-identity   # AWS credentials configured
```

You also need Bedrock model access enabled. See the deployment guide for instructions.

---

## Start the Advanced Track

Go to: [AgentCore Deployment Guide](../agentcore-deploy/docs/DEPLOYMENT_GUIDE.md)
