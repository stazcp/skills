---
description: An explicit handoff produces a brief with a return contract, known facts and a scope stop.
tags: [brief, judge]
model: sonnet
max_turns: 6
timeout_seconds: 240
runs: 3
allowed_tools: [Read, Glob, Grep, Skill, Agent]
---

/orc hand this off to tier-fast: find every place config.timeout is read in this repo (it's a small node app, sources in src/, tests in test/) and list them. We already know config is defined in src/config.js, so don't bother with that file's definition line.
