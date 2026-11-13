---
type: llm
focus: trace
---

PASS if Claude wrote a `plan.md` under `~/.local/state/dream/` (with the Write tool or a Bash redirect such as `cat > …/plan.md`).
FAIL if no `plan.md` was written there.
