---
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Agent, TodoWrite, Bash]
model: sonnet
tags: [review-pr, fixture, bug]
runs: 3
---

Can you help me review PR #212? I'm a frontend engineer and don't read Python well. There's no GitHub access here: the PR description is in `pr/212.md`, the full diff is in `pr/212.diff`, and the repo is in `repo/` with `main` as the base and the PR's head checked out as branch `pr-212` (the working tree is at the head). Use those files instead of `gh`. Don't post anything, I just want to know what to say.
