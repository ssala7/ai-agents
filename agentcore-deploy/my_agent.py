"""
My Agent — deployed on AWS Bedrock AgentCore Runtime
A simple but complete agent with tools, ready for cloud deployment.
"""

import json
from datetime import datetime, timezone

from strands import Agent, tool
from bedrock_agentcore.runtime import BedrockAgentCoreApp

# ── System prompt ────────────────────────────────────────────────────────────

SYSTEM_PROMPT = """
You are a helpful assistant with access to tools.
When asked about the weather, use get_weather.
When asked to calculate something, use calculate.
When asked for the current time, use get_current_time.
Always be concise and accurate.
"""

# ── Tools ────────────────────────────────────────────────────────────────────

@tool
def get_weather(city: str) -> str:
    """Get current weather for a city (simulated)."""
    # Replace with a real weather API call (e.g. OpenWeatherMap) in production
    mock_data = {
        "london":    {"temp": "15°C", "condition": "Cloudy"},
        "new york":  {"temp": "22°C", "condition": "Sunny"},
        "bangalore": {"temp": "28°C", "condition": "Partly cloudy"},
    }
    data = mock_data.get(city.lower(), {"temp": "N/A", "condition": "Unknown city"})
    return json.dumps({"city": city, **data})


@tool
def calculate(expression: str) -> str:
    """Safely evaluate a basic math expression like '2 + 2' or '10 * 5'."""
    try:
        # Only allow safe characters
        allowed = set("0123456789+-*/(). ")
        if not all(c in allowed for c in expression):
            return json.dumps({"error": "Invalid characters in expression"})
        result = eval(expression, {"__builtins__": {}})  # noqa: S307
        return json.dumps({"expression": expression, "result": result})
    except Exception as e:
        return json.dumps({"error": str(e)})


@tool
def get_current_time() -> str:
    """Return the current UTC date and time."""
    return json.dumps({"utc_time": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")})


# ── AgentCore app ─────────────────────────────────────────────────────────────

app = BedrockAgentCoreApp()

agent = Agent(
    model="anthropic.claude-3-haiku-20240307-v1:0",   # cross-region inference profile
    system_prompt=SYSTEM_PROMPT,
    tools=[get_weather, calculate, get_current_time],
)


@app.entrypoint
def invoke(payload: dict) -> str:
    """Entry point called by AgentCore Runtime on every invocation."""
    prompt = payload.get("prompt", "Hello! What can you help me with?")
    response = agent(prompt)
    return response.message["content"][0]["text"]


# ── Local dev entry point ─────────────────────────────────────────────────────

if __name__ == "__main__":
    app.run()
