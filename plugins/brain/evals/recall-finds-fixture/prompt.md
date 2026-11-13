---
description: /brain ? <query> answers from the fixture vault and cites the note; writes nothing.
tags: [brain, recall]
max_turns: 25
timeout_seconds: 420
allowed_tools: [Read, Glob, Grep, Skill, Bash]
model: sonnet
runs: 3
---

/brain ? what's the batch size cap for offline sync, and why?
