#!/usr/bin/env bash
# =============================================================================
# 02_launch_local.sh — Run and test the agent locally before cloud deploy
#
# What this does:
#   1. Activates the virtual environment
#   2. Launches the agent locally via `agentcore launch --local`
#   3. Runs 3 test invocations against the local endpoint
#
# Prerequisites:
#   - 01_configure.sh has been run
#   - Docker is running (AgentCore uses a local container for isolation)
#
# Usage:
#   ./scripts/02_launch_local.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/.venv"

source "$VENV_DIR/bin/activate"
cd "$PROJECT_DIR"

echo "==> Launching agent locally (runs in a local container)..."
echo "     Press Ctrl+C to stop the local server when done testing."
echo ""

# Launch in background so we can run test invocations
agentcore launch --local &
LAUNCH_PID=$!

# Clean up background process on exit/error
trap "kill $LAUNCH_PID 2>/dev/null" EXIT

# Give it time to start
echo "     Waiting 10s for local server to be ready..."
sleep 10

echo ""
echo "==> Running test invocations..."
echo ""

echo "--- Test 1: Simple greeting ---"
agentcore invoke --local '{"prompt": "Hello! What can you do?"}'
echo ""

echo "--- Test 2: Weather tool ---"
agentcore invoke --local '{"prompt": "What is the weather in London?"}'
echo ""

echo "--- Test 3: Calculator tool ---"
agentcore invoke --local '{"prompt": "What is 123 * 456?"}'
echo ""

echo "--- Test 4: Time tool ---"
agentcore invoke --local '{"prompt": "What time is it right now?"}'
echo ""

echo "  Local tests complete."
echo "    Stop the local server with Ctrl+C, then run ./scripts/03_deploy_cloud.sh"

# Wait for user to stop
wait $LAUNCH_PID
