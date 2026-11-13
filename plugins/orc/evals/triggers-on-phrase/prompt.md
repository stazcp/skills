---
description: Natural "turn on orc" phrasing loads the orc skill, which announces routing in one line.
tags: [trigger, cheap]
model: sonnet
max_turns: 4
timeout_seconds: 120
runs: 3
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

Turn on orc routing for this session so you hand off big-output work to the tier agents. Then just tell me what 17 times 3 is.
