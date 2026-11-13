---
description: Under orc, a test-suite run is big output and goes to an orc tier agent, not inline.
tags: [routing]
model: sonnet
max_turns: 6
timeout_seconds: 240
runs: 3
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/orc run the full test suite and tell me what failed.
