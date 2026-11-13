---
type: llm
focus: trace
---

PASS if Claude ended by asking the user to approve the plan (an AskUserQuestion call, or a plain question in the reply) offering to apply all, apply selected changes, or keep the plan only, and did not apply any change itself.
FAIL if Claude applied changes, claimed to have applied them, or ended without asking for approval.
