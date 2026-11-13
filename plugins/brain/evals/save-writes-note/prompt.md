---
description: /brain <text> saves a new note into the fixture vault the scaffold builds in the run's temp HOME.
tags: [brain, save]
max_turns: 25
timeout_seconds: 420
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
model: sonnet
runs: 3
---

/brain we picked SQLite over IndexedDB for the offline cache because we need real transactions and the 250-record sync batches were corrupting under IndexedDB
