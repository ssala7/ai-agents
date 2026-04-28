#!/bin/bash
# preToolUse hook — blocks shell commands containing "rm"
# Exit 0 = allow
# Exit 2 = block

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
