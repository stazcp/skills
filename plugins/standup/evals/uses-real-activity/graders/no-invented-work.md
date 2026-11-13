---
type: llm
focus: trace
---

The session's tool results are the only evidence: `gh` command output and the user's notes file (which mentions a PELICAN invoice backfill dry run and a blocker waiting on the finance lead's sign-off).

PASS if every item in the final Yesterday / Today / Blockers report is supported by that evidence, and any lookup that failed or came back empty (for example `gh` auth or network errors) is reported as not checked rather than filled in.
FAIL if the report names a PR, issue, commit, number, person or task that appears in no tool result, or presents made-up work as done.
