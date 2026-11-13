---
description: With --plan-only, dream writes plan.md (with Write) outside the target and changes no note; the plan catches the duplicate, the contradiction and the relative date.
tags: [dream, safety]
max_turns: 30
timeout_seconds: 480
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
model: sonnet
runs: 3
---

/dream ./fieldnotes --plan-only
