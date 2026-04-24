#!/usr/bin/env bash
# =============================================================================
# 03_deploy_cloud.sh — Deploy the agent to AWS AgentCore Runtime
#
# What this does:
#   1. Activates the virtual environment
#   2. Runs `agentcore launch` to build + push container image to ECR
#      and create a live AgentCore Runtime endpoint
#   3. Polls `agentcore status` until the endpoint is READY
#   4. Runs a live invocation against the cloud endpoint
#
# Prerequisites:
#   - 01_configure.sh has been run
#   - 02_launch_local.sh tests passed
#   - Docker is running (needed to build the container image)
#   - AWS credentials have ECR push + AgentCore permissions
#
# Usage:
#   ./scripts/03_deploy_cloud.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/.venv"
MAX_WAIT=300   # seconds to wait for endpoint to become READY
POLL_INTERVAL=15

source "$VENV_DIR/bin/activate"
cd "$PROJECT_DIR"

echo "==> [1/3] Deploying agent to AWS AgentCore Runtime..."
echo "     This will:"
echo "       - Build a container image from your code"
echo "       - Push it to your ECR repository"
echo "       - Create a serverless AgentCore Runtime endpoint"
echo ""
agentcore launch

echo ""
echo "==> [2/3] Waiting for endpoint to become READY (max ${MAX_WAIT}s)..."
ELAPSED=0
while [ $ELAPSED -lt $MAX_WAIT ]; do
    STATUS=$(agentcore status 2>&1)
    echo "     [$ELAPSED s] $STATUS"
    if echo "$STATUS" | grep -qi "READY\|running\|active"; then
        break
    fi
    sleep $POLL_INTERVAL
    ELAPSED=$((ELAPSED + POLL_INTERVAL))
done

echo ""
echo "==> [3/3] Running live cloud invocation..."
echo ""

echo "--- Cloud Test: Weather ---"
agentcore invoke '{"prompt": "What is the weather in New York?"}'
echo ""

echo "--- Cloud Test: Calculator ---"
agentcore invoke '{"prompt": "Calculate 2 to the power of 10"}'
echo ""

echo ""
echo "✅  Deployment complete!"
echo ""
echo "    Useful commands:"
echo "      agentcore status              — check endpoint status"
echo "      agentcore invoke '<payload>'  — invoke the live endpoint"
echo "      agentcore logs                — view runtime logs"
echo ""
echo "    To set up X-Ray observability:"
echo "      aws xray update-trace-segment-destination --destination CloudWatchLogs"
echo "      aws xray update-indexing-rule --name Default --rule '{\"Probabilistic\":{\"DesiredSamplingPercentage\":1}}'"
