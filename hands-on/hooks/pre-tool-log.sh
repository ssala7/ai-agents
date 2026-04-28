#!/bin/bash
# preToolUse hook — logs every tool call to a file
# Exit 0 = allow the tool call
# Exit 2 = block the tool call

LOG_FILE="/tmp/kiro-hook-log.txt"

INPUT=$(cat)

# Log the raw input so we can see the structure
echo "[$(date '+%H:%M:%S')] RAW: $INPUT" >> "$LOG_FILE"

# Try common field names
TOOL_NAME=$(echo "$INPUT" | python3 -c "
import sys, json
d = json.load(sys.stdin)
name = d.get('toolName') or d.get('tool_name') or d.get('name') or d.get('tool', {}).get('name') or 'unknown'
print(name)
" 2>/dev/null)

echo "[$(date '+%H:%M:%S')] Tool: $TOOL_NAME" >> "$LOG_FILE"

exit 0
