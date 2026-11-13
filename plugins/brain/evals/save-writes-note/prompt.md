---
description: /brain <text> saves a new note into the fixture vault the scaffold builds in the run's temp HOME. The topic is one the vault has no note on, so creating a note (not appending, SKILL.md §5) is the right move.
tags: [brain, save]
max_turns: 25
timeout_seconds: 420
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
model: sonnet
runs: 3
---

/brain we picked pnpm workspaces over Yarn for the monorepo because cold installs in CI dropped from 6 minutes to 2 and Yarn's hoisting kept breaking the Storybook build
