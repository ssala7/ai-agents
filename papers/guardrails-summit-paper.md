# Guardrails for AI Agents: From Local Hooks to Production Safety

**Author:** Suresh Sala
**Format:** Summit Talk / Paper (30 minutes)
**Audience:** Developers building or deploying AI agents

---

## Abstract

AI agents don't just generate text — they execute real commands, modify files, call APIs, and interact with production systems. Without guardrails, a single misinterpreted prompt can delete data, leak secrets, or run up cloud bills. This paper presents a defense-in-depth approach to AI agent safety across three layers: tool-level restrictions for access control, runtime hooks for real-time interception, and Amazon Bedrock Guardrails for content safety at scale. Each layer is demonstrated with working code, and together they form a complete safety architecture from local development to production deployment.

---

## 1. The Problem: Agents Have Hands

A chatbot that gives bad advice is annoying. An agent that executes bad advice is dangerous.

```
Chatbot:
  User: "Clean up the project"
  Bot: "You can run: rm -rf node_modules && npm install"  ← suggestion only

Agent:
  User: "Clean up the project"
  Agent: [executes: rm -rf /]                              ← actually does it
  Agent: "Done. Cleaned up."
```

Modern AI agents have access to:
- File system (read, write, delete)
- Shell commands (arbitrary execution)
- Cloud APIs (AWS, databases, deployments)
- Network (web requests, API calls)

The model is probabilistic — it picks actions based on pattern matching, not deterministic rules. It can:
- Choose the wrong tool
- Hallucinate parameters
- Misinterpret ambiguous instructions
- Follow injected instructions from untrusted content

**Guardrails are not optional. They are architecture.**

---

## 2. Defense in Depth: Three Layers

```
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: CONTENT SAFETY (Bedrock Guardrails)               │
│  Filters harmful content, blocks topics, redacts PII        │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Layer 2: RUNTIME HOOKS (preToolUse / postToolUse)    │  │
│  │  Intercepts and inspects every tool call in real-time  │  │
│  │                                                        │  │
│  │  ┌─────────────────────────────────────────────────┐  │  │
│  │  │  Layer 1: TOOL RESTRICTIONS                     │  │  │
│  │  │  Controls which tools exist and what they can do │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

No single layer is sufficient. Each catches what the others miss.

---

## 3. Layer 1: Tool Restrictions

### Concept

Control what the agent CAN do before it even tries. This is the coarsest but most reliable layer — if a tool isn't available, the model cannot call it.

### Implementation

```json
{
  "tools": ["read", "write", "shell", "grep", "glob"],
  "allowedTools": ["read", "grep", "glob"],
  "toolsSettings": {
    "write": {
      "allowedPaths": ["src/**", "tests/**"],
      "deniedPaths": [".env", "*.key", "*.pem", "node_modules/**"]
    },
    "shell": {
      "allowedCommands": ["npm test", "npm run build", "python -m pytest"]
    }
  }
}
```

### What each setting does

| Setting | Purpose | Failure mode it prevents |
|---------|---------|--------------------------|
| `tools` | Which tools are available at all | Agent can't call tools that don't exist |
| `allowedTools` | Which tools run without human approval | Dangerous tools require confirmation |
| `allowedPaths` | Restrict file access to specific directories | Agent can't write to production configs |
| `deniedPaths` | Block access to sensitive files | Secrets, keys, and credentials are protected |
| `allowedCommands` | Whitelist specific shell commands | Agent can't run arbitrary commands |

### Key principle

**Start restrictive, expand as needed.** Give the agent read-only access first. Add write and shell only for specific tasks, with path and command restrictions.

### Limitations

Tool restrictions are static — they don't inspect the content of what's being written or the context of why a command is being run. An agent restricted to `npm test` can still run `npm test` in a way that triggers unexpected side effects. For dynamic inspection, you need Layer 2.

---

## 4. Layer 2: Runtime Hooks

### Concept

Hooks are scripts that run before or after every tool call. They receive the full context (tool name, parameters, session ID) and can allow or block the operation in real-time.

```
Agent wants to call shell("rm -rf /tmp/data")
       │
       ▼
┌──────────────────────────────┐
│  preToolUse hook runs        │
│  Receives: {                 │
│    "tool_name": "shell",     │
│    "tool_input": {           │
│      "command": "rm -rf..."  │
│    }                         │
│  }                           │
│                              │
│  exit 0 → ALLOW             │
│  exit 2 → BLOCK             │
└──────────────────────────────┘
```

### Working example: Block destructive commands

```bash
#!/bin/bash
# block-rm.sh — preToolUse hook
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(d.get('tool_input', {}).get('command', ''))
" 2>/dev/null)

if echo "$COMMAND" | grep -q "rm "; then
    echo "BLOCKED: refusing to run command containing 'rm'" >&2
    exit 2
fi
exit 0
```

### Working example: Audit logging

```bash
#!/bin/bash
# audit-log.sh — preToolUse hook
LOG="/var/log/agent-audit.jsonl"
INPUT=$(cat)
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
echo "{\"ts\":\"$TIMESTAMP\",\"event\":$INPUT}" >> "$LOG"
exit 0
```

### Hook configuration

```json
{
  "hooks": {
    "preToolUse": [
      { "command": "/path/to/audit-log.sh" },
      { "matcher": "shell", "command": "/path/to/block-rm.sh" },
      { "matcher": "write", "command": "/path/to/check-secrets.sh" }
    ],
    "postToolUse": [
      { "matcher": "shell", "command": "/path/to/scan-output.sh" }
    ]
  }
}
```

### Real-world hook use cases

| Hook | What it does | Prevents |
|------|-------------|----------|
| Block destructive commands | Reject `rm`, `drop`, `delete` | Data loss |
| PII scanner | Check file writes for SSN, credit cards | Data leakage |
| Cost limiter | Count API calls, block after threshold | Runaway costs |
| Secret detector | Block writes containing API keys | Credential exposure |
| Audit trail | Log every tool call with timestamp | Compliance gaps |
| Rate limiter | Throttle tool calls per minute | Resource exhaustion |

### How the agent handles blocks

When a hook returns exit 2, the agent receives an error and adapts:

```
Agent: [tries to run rm /tmp/data]
Hook:  BLOCKED
Agent: "The deletion was blocked by a safety hook. The file /tmp/data
        was not deleted. Would you like me to try a different approach?"
```

The agent doesn't crash — it observes the failure and reasons about it. This is the Think-Act-Observe loop handling guardrails gracefully.

### Limitations

Hooks run locally and are only as smart as the script you write. They can't understand intent or context deeply. For content-level safety (is this response harmful? is this a prompt injection?), you need Layer 3.

---

## 5. Layer 3: Amazon Bedrock Guardrails

### Concept

Bedrock Guardrails is a managed service that evaluates both inputs (user prompts) and outputs (model responses) against configurable policies. It operates at the content level — understanding meaning, not just pattern matching.

```
User prompt → [Bedrock Guardrails: INPUT check] → Model → [Bedrock Guardrails: OUTPUT check] → Response
                     │                                              │
                     ▼                                              ▼
              Block harmful                                  Block harmful
              prompts before                                 responses before
              they reach model                               they reach user
```

### Six safeguards

| Safeguard | What it does | Example |
|-----------|-------------|---------|
| **Content filters** | Block harmful content by category (hate, violence, sexual, misconduct, prompt attacks) | Block responses with violence score > medium |
| **Denied topics** | Prevent discussion of specific subjects | Block investment advice, medical diagnoses |
| **Word filters** | Block specific words or patterns | Block competitor names, profanity |
| **Sensitive information filters** | Detect and redact PII | Mask SSN, credit card numbers, email addresses |
| **Contextual grounding** | Detect hallucinations by checking against source | Flag responses not grounded in provided context |
| **Automated Reasoning** | Mathematical/logical verification of factual claims | Verify numerical calculations, policy compliance |

### Creating a guardrail

```python
import boto3

client = boto3.client("bedrock", region_name="us-east-1")

response = client.create_guardrail(
    name="agent-safety",
    description="Safety guardrail for production agent",
    
    # Block harmful content
    contentPolicyConfig={
        "filtersConfig": [
            {"type": "HATE", "inputStrength": "HIGH", "outputStrength": "HIGH"},
            {"type": "VIOLENCE", "inputStrength": "HIGH", "outputStrength": "HIGH"},
            {"type": "PROMPT_ATTACK", "inputStrength": "HIGH", "outputStrength": "NONE"},
        ]
    },
    
    # Block specific topics
    topicPolicyConfig={
        "topicsConfig": [
            {
                "name": "financial-advice",
                "definition": "Providing specific investment recommendations or financial planning advice",
                "type": "DENY"
            }
        ]
    },
    
    # Redact PII
    sensitiveInformationPolicyConfig={
        "piiEntitiesConfig": [
            {"type": "EMAIL", "action": "ANONYMIZE"},
            {"type": "PHONE", "action": "ANONYMIZE"},
            {"type": "US_SOCIAL_SECURITY_NUMBER", "action": "BLOCK"},
            {"type": "CREDIT_DEBIT_CARD_NUMBER", "action": "BLOCK"},
        ]
    },
    
    # Blocked message shown to user
    blockedInputMessaging="I cannot process this request due to safety policies.",
    blockedOutputsMessaging="I cannot provide this response due to safety policies.",
)

guardrail_id = response["guardrailId"]
print(f"Created guardrail: {guardrail_id}")
```

### Applying guardrails to an agent

```python
from strands import Agent

agent = Agent(
    model="anthropic.claude-3-haiku-20240307-v1:0",
    system_prompt="You are a helpful assistant.",
    tools=[get_weather, calculate],
    # Attach guardrail
    guardrail_config={
        "guardrailIdentifier": "your-guardrail-id",
        "guardrailVersion": "DRAFT",  # or specific version number
    }
)
```

### Using the ApplyGuardrail API independently

You can also apply guardrails to any text — not just Bedrock model calls:

```python
response = client.apply_guardrail(
    guardrailIdentifier="your-guardrail-id",
    guardrailVersion="DRAFT",
    source="OUTPUT",
    content=[{"text": {"text": "The user's SSN is 123-45-6789"}}]
)

# response["action"] = "GUARDRAIL_INTERVENED"
# PII is redacted in the output
```

This means you can use Bedrock Guardrails with any model provider — not just Bedrock models.

### Contextual grounding: Detecting hallucinations

```python
response = client.create_guardrail(
    name="grounded-agent",
    contextualGroundingPolicyConfig={
        "filtersConfig": [
            {"type": "GROUNDING", "threshold": 0.7},   # response must be grounded in source
            {"type": "RELEVANCE", "threshold": 0.7},   # response must be relevant to query
        ]
    },
    ...
)
```

When the agent responds, Bedrock checks if the response is actually supported by the provided context. If not, it flags or blocks the response.

---

## 6. Putting It All Together: Defense in Depth

### Local development

```
┌─────────────────────────────────────────┐
│  Your Machine                            │
│                                          │
│  Agent Config:                           │
│    tools: [read, write, shell]           │  ← Layer 1
│    allowedTools: [read]                  │
│    toolsSettings: {restricted}           │
│                                          │
│  Hooks:                                  │
│    preToolUse: [audit, block-rm]         │  ← Layer 2
│    postToolUse: [scan-output]            │
└─────────────────────────────────────────┘
```

### Production deployment

```
┌─────────────────────────────────────────────────────────────┐
│  AWS                                                         │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Bedrock Guardrails                                    │ │
│  │  • Content filters (hate, violence, prompt attacks)    │ │
│  │  • PII redaction (SSN, credit cards, emails)           │ │
│  │  • Denied topics (financial advice, medical)           │ │
│  │  • Contextual grounding (hallucination detection)      │ │ ← Layer 3
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  AgentCore Runtime                                     │ │
│  │  • IAM role with least-privilege                       │ │
│  │  • Tool restrictions in agent code                     │ │ ← Layer 1
│  │  • CloudWatch logging + X-Ray tracing                  │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                   │
│                          ▼                                   │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  Agent Code                                            │ │
│  │  • Input validation in @tool functions                 │ │ ← Layer 2
│  │  • Character allowlists for eval()                     │ │   (code-level)
│  │  • Error handling that doesn't leak internals          │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Which layer catches what

| Threat | Layer 1 | Layer 2 | Layer 3 |
|--------|---------|---------|---------|
| Agent runs `rm -rf /` | ✅ allowedCommands | ✅ hook blocks `rm` | — |
| Agent writes API key to file | ✅ deniedPaths for .env | ✅ hook scans for secrets | — |
| User asks for bomb-making instructions | — | — | ✅ Content filter |
| Agent leaks user's SSN in response | — | — | ✅ PII redaction |
| Agent hallucinates fake data | — | — | ✅ Contextual grounding |
| Agent calls tool 1000 times in a loop | — | ✅ Rate limiter hook | — |
| Prompt injection in uploaded file | — | — | ✅ Prompt attack filter |
| Agent writes to production database | ✅ Tool not available | ✅ Hook checks target | — |

---

## 7. Recommendations

### For local development
1. Start with `allowedTools: ["read", "grep", "glob"]` — read-only by default
2. Add a preToolUse audit hook from day one — you'll want the logs
3. Use `deniedPaths` to protect `.env`, keys, and credentials
4. Test with intentionally adversarial prompts before expanding permissions

### For production
1. Always attach Bedrock Guardrails — content filters + PII redaction at minimum
2. Use IAM least-privilege for the agent's execution role
3. Enable CloudWatch logging and X-Ray tracing for observability
4. Set up CloudWatch alarms for guardrail intervention rates
5. Use contextual grounding if the agent answers from documents (RAG)
6. Review and version your guardrail policies like code

### The golden rule

**No single layer is enough.** Tool restrictions prevent the agent from having dangerous capabilities. Hooks inspect and block dangerous actions in real-time. Bedrock Guardrails catch harmful content that passes through both. Together, they form a complete safety architecture.

---

## 8. Demo Summary

| Demo | What it shows | Time |
|------|--------------|------|
| Tool restrictions config | Agent can only run `npm test`, can't write to `.env` | 2 min |
| preToolUse hook (block-rm) | Hook intercepts and blocks destructive command | 3 min |
| preToolUse hook (audit log) | Every tool call logged with full context | 2 min |
| Bedrock Guardrail creation | Create guardrail with content + PII + topic policies | 3 min |
| Guardrail in action | Agent response blocked/redacted by guardrail | 3 min |

All demo code available at: `github.com/ssala7/ai-agents`

---

## References

- [Amazon Bedrock Guardrails Documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html)
- [Agent Skills Standard](https://agentskills.io)
- [Strands Agents SDK](https://github.com/strands-agents/sdk-python)
- [AI Agents Curriculum](https://github.com/ssala7/ai-agents) — Module 3: Tools, Section 3.7-3.8

---

## About the Author

Suresh Sala is a developer focused on AI agent architecture and production deployment. He maintains an open-source curriculum for teaching AI agents from fundamentals to production, covering agent internals, tool systems, multi-agent coordination, and AWS deployment.
