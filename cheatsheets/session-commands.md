# Session Management — Cheat Sheet

## Quick Reference

### Spawn a Session
```json
{"command": "spawn_session", "agent_name": "kiro_default", "task": "Review auth code", "name": "auth-reviewer", "group": "review-team"}
```
Creates a new agent session. Like hiring someone for a specific job.

---

### Send a Message
```json
{"command": "send_message", "target": "auth-reviewer", "message": "Focus on SQL injection risks", "priority": "normal"}
```
Priority options: `normal` | `escalation`

Escalation without a target auto-routes to the parent session.

---

### Read Messages (check inbox)
```json
{"command": "read_messages", "limit": 5}
```

---

### List Sessions
```json
{"command": "list_sessions", "filter": "active"}
```
Filter options: `active` | `idle` | `busy` | `terminated` | `all`

---

### Get Session Status
```json
{"command": "get_session_status", "target": "auth-reviewer", "verbose": true}
```

---

### Interrupt a Session
```json
{"command": "interrupt", "target": "auth-reviewer", "message": "Stop! New priority: check XSS vulnerabilities"}
```
Redirects a running session to a completely new task.

---

### Inject Context (silent)
```json
{"command": "inject_context", "target": "auth-reviewer", "context": "The app uses JWT tokens with RS256 signing"}
```
Adds info without triggering a new turn — like slipping a note under the door.

---

### Manage Groups
```json
// Create a group
{"command": "manage_group", "action": "create", "group": "review-team"}

// Add session to group
{"command": "manage_group", "action": "add", "group": "review-team", "target": "auth-reviewer", "role": "security"}

// Broadcast to all in group
{"command": "manage_group", "action": "broadcast", "group": "review-team", "message": "Submit your findings now"}

// List group members
{"command": "manage_group", "action": "list", "group": "review-team"}

// Remove from group
{"command": "manage_group", "action": "remove", "group": "review-team", "target": "auth-reviewer"}
```

---

### Revive a Terminated Session
```json
{"command": "revive_session", "target": "auth-reviewer", "task": "Now review the password reset flow"}
```
Brings back a finished session with a new task, keeping its name and group.

---

## User-Facing Commands

| Command | What you type | Effect |
|---------|--------------|--------|
| Spawn | `/spawn Analyze test coverage` | Creates parallel session |
| Monitor | `Ctrl+G` | Opens crew monitor (see all sessions) |

---

## Session Lifecycle

```
spawn_session → active → (completes task) → terminated
                  │                              │
                  │ interrupt                     │ revive_session
                  ▼                              ▼
               redirected                    active again
```

---

## Mental Model

Think of sessions as team members in a Slack workspace:

| Concept | Slack Analogy |
|---------|--------------|
| Session | A team member |
| Group | A channel |
| send_message | DM |
| broadcast | @channel |
| interrupt | "Drop everything, new priority" |
| inject_context | Pinning a doc in the channel |
| spawn_session | Hiring a contractor |
| revive_session | Re-engaging a past contractor |
