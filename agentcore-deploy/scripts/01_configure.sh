#!/usr/bin/env bash
# =============================================================================
# 01_configure.sh — Set up the AgentCore project (run once)
#
# What this does:
#   1. Creates and activates a Python virtual environment
#   2. Installs all dependencies
#   3. Runs `agentcore configure` to create the IAM role + ECR repo
#
# Prerequisites:
#   - Python 3.11+
#   - AWS CLI configured (aws configure)
#   - AWS account with Bedrock model access enabled
#
# Usage:
#   chmod +x scripts/01_configure.sh
#   ./scripts/01_configure.sh
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$PROJECT_DIR/.venv"
AGENT_FILE="my_agent.py"

echo "==> [1/3] Creating Python virtual environment at $VENV_DIR"
python3 -m venv "$VENV_DIR"
source "$VENV_DIR/bin/activate"

echo "==> [2/3] Installing dependencies"
pip install --upgrade pip -q
pip install -r "$PROJECT_DIR/requirements.txt" -q
echo "     Done. Installed: $(pip show bedrock-agentcore | grep Version)"

echo "==> [3/3] Running agentcore configure"
echo "     This will:"
echo "       - Auto-create an IAM execution role"
echo "       - Auto-create an ECR repository for the container image"
echo "       - Detect requirements.txt"
echo "       - Enable observability by default"
echo ""
cd "$PROJECT_DIR"
agentcore configure --entrypoint "$AGENT_FILE"

echo ""
echo "  Configuration complete."
echo "    Next step: run ./scripts/02_launch_local.sh to test locally"
