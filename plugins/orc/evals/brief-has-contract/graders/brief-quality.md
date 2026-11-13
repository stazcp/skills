---
type: llm
focus: trace
---

Look only at the `prompt` field of the first Agent tool call in the trace (the brief sent to the subagent).

PASS if that brief contains all three:
1. A return contract: it states the exact shape of the answer to return (for example a `file:line` list with one phrase each, or a line limit) and/or says not to paste logs or file contents.
2. Known facts: it passes on what the user already said, at least that config is defined in src/config.js (or that its definition line is excluded) or that sources are in src/ and tests in test/.
3. A scope stop: it tells the worker to stop and report (for example with `STUCK:`) rather than widen the task if it turns out bigger or different than briefed.

FAIL if there is no Agent call, or the brief is missing any one of the three.
