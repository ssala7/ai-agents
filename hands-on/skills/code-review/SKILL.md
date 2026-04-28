---
name: code-review
description: Review code for bugs, security issues, and best practices. Use when reviewing code, checking for problems, or preparing a pull request.
---

## Code Review Checklist

When reviewing code, follow this checklist in order:

### 1. Security
- Check for hardcoded secrets (API keys, passwords, tokens)
- Look for SQL injection or command injection risks
- Verify input validation on user-provided data
- Check for proper error handling that doesn't leak internals

### 2. Bugs
- Look for off-by-one errors
- Check null/undefined handling
- Verify edge cases (empty arrays, zero values, negative numbers)
- Look for race conditions in async code

### 3. Best Practices
- Functions should do one thing
- Variable names should be descriptive
- No magic numbers — use named constants
- DRY — flag duplicated logic

### 4. Output Format

Present findings as:

```
## Review Summary

**Security:** [issues found or "No issues"]
**Bugs:** [issues found or "No issues"]  
**Best Practices:** [suggestions or "Looks good"]

### Issues (if any)
1. [file:line] Description of issue — severity (high/medium/low)
```
