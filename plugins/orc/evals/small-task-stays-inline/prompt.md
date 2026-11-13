---
description: Under orc, a screen-or-less answer stays inline; no Agent is dispatched.
tags: [routing, cheap]
model: sonnet
max_turns: 4
timeout_seconds: 120
runs: 3
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/orc what's 2+2?
