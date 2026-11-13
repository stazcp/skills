---
description: After "orc off" the session acknowledges in one line and stops routing to tier agents.
tags: [routing, off]
model: sonnet
max_turns: 6
timeout_seconds: 180
runs: 3
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

Turn on orc routing. Actually, orc off: I don't want any handoffs today. Read src/config.js and tell me the default timeout value.
