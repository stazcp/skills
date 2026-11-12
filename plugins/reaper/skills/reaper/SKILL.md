---
name: reaper
description: "Work through a curated list of small issues in a GitHub repo: pick one a human has labelled for Reaper, check it is still worth doing (closing stale AI-generated issues), claim it, fix it, prove the fix with tests, CI and screenshots or video, and open a ready PR that says no human has read it. Capped by how many Reaper PRs are waiting for review, so it never outruns the team. Use when the user says /reaper, \"run reaper\", \"reap an issue\", or schedules it."
argument-hint: "[--dry-run] [--issue <n>] [--status]"
---

# Reaper

Reaper takes micro-tasks off engineers' plates. A human curates the work by labelling issues; Reaper checks each one is still valid, fixes it, proves the fix and opens a PR for a human to approve. The human who approves becomes accountable for the change.

## Modes

- `/reaper`: one pass. Check capacity, pick **one** issue, triage it, and work it to an open PR. One issue per run keeps each run reviewable.
- `/reaper --dry-run`: check capacity, pick and triage, then **stop before any write**. Print what it would close, claim or work on. Use this for the first runs on a repo.
- `/reaper --issue <n>`: skip picking and work issue `<n>`, which must still pass every check below.
- `/reaper --status`: list Reaper's work in the repo by state (in progress, waiting for review, merged, closed, rejected), from GitHub alone. Read-only.

## Config

Run from inside the target repo's checkout. Find `<owner>/<repo>` with `gh repo view --json nameWithOwner`, then read `<context>/reaper/<owner>-<repo>.yaml`, where `<context>` is `$SKILLZ_CONTEXT` or `~/.config/skillz`. `config.example.yaml` next to this file lists every key.

**No config file means stop.** Say where it should go and point at the example. Never guess a label, cap or path.

**The repo's own agent instructions win.** Read its `CLAUDE.md` / `AGENTS.md` (and whatever they say to read first) before touching code, and follow them over anything here: branch naming, attribution footers, PR skills, files agents must never read.

## The pass

### 1. Capacity

- Count open PRs with the `labels.pr` label. If the count is at `caps.max_in_review` or above, stop: "N Reaper PRs are waiting for review; nothing new until one lands or closes."
- Count Reaper PRs and closes made today (local date). At `caps.daily_max`, stop.
- Before starting new work, look after open Reaper PRs first (step 9). An open PR that needs a fix beats a new issue.

### 2. Pick

```bash
gh issue list --label <labels.pick> --state open --search "no:assignee" --json number,title,labels,author,createdAt,body
```

Keep only issues that also carry one of `pick.types` and none of `pick.exclude_labels`. Oldest first. If a branch `<branch_prefix><n>-*` already exists for an issue, it was worked before: resume it (step 6), never start over.

### 3. Triage against the default branch

`git fetch` first. Read the issue and **every** comment. Then check, against current `origin/<default>`:

- Is the code it names still there?
- Does the bug still reproduce, or the debt still exist? Reproduce if it's cheap.
- Did a merged PR already fix it? `gh pr list --state merged --search "<issue number or key terms>"`, plus `git log -S` on the symbol.

Outcomes:

- **Still valid:** go on to step 4.
- **Fixed, gone or not worth doing**, and the issue is AI-generated (see below): close it. Use `--reason "not planned"`, and a comment that names the reason (`stale` or `not worth doing`) and gives the evidence: the commit, the PR, or the check you ran and what it showed.
- **Same, but a human filed it:** do not close it. Comment what you found with the evidence, remove the `labels.pick` label, and leave the call to them.

An issue is AI-generated when its author is in `ai_generated.authors`, or it carries a label in `ai_generated.labels`, or its body contains one of `ai_generated.body_markers`. When unsure, treat it as human-filed.

### 4. Shallow gate

The task fits Reaper only if all of these hold. Judge from the issue and the code before writing anything:

- the expected diff is under `limits.max_diff_lines`;
- it touches one area or service;
- it touches nothing matching `limits.excluded_paths`;
- it has a repro or acceptance criteria.

If it fails, reject: comment why in one or two sentences, remove `labels.pick`, add `labels.rejected`. A rejection teaches the curator what a Reaper task looks like, so make the reason specific ("needs a schema change in X").

### 5. Claim

Assign the issue to `identity.assignee`. If `project` is configured, set the item's `project.status_field` to `project.in_progress`. Claim before working so a person never duplicates it.

### 6. Fix

- Work in a fresh worktree off `origin/<default>` on branch `<branch_prefix><n>-<short-slug>`. Never in the user's main checkout.
- **Reproduce first.** A UI bug gets a Playwright screenshot (and video when the bug involves interaction) showing it broken. A backend bug gets a test that fails. A flake gets repeated runs showing it failing.
- Fix it, the smallest change that does the job.
- **Re-check the shallow gate on the actual diff.** Over the line limit, or touching an excluded path, means stop: reject as in step 4. Keep the branch; say so in the comment.

### 7. Verify

- Run the tests that cover the change, not the whole suite.
- Collect the evidence: before and after screenshots or video, the failing-then-passing test, the CI run link.
- Upload images and video with `evidence.upload` and use the links it returns. The GitHub API can't attach files to a PR, and CI artifacts expire. **Never commit evidence into the repo.**

### 8. Open the PR

Use the repo's own PR skill if its instructions name one; otherwise `gh pr create`. Always:

- ready for review, **never draft**;
- labels: `labels.pr` plus every label in `pr.extra_labels`;
- the body starts with this banner, verbatim:

  > ⚠️ **AI-generated code and description. No human has read this PR.** It was written by Reaper from #<issue>. By approving it you take on the responsibility the author normally carries: you are accountable for this change as if you had written it.

- then: `Closes #<issue>`, how triage confirmed it's still valid, what changed and why, the evidence links, and whatever footer the repo's instructions require.

### 9. Follow through

- Hand the PR to the repo's PR loop skill if its instructions name one (`pr.loop_skill`), for at most `caps.fix_rounds` rounds of fixing CI and review comments.
- E2E reruns stop at `caps.e2e_reruns`. After that, comment on the PR what failed, and leave it for a human.
- **Never force-push a Reaper branch.** A closed PR can only be reopened if its branch wasn't force-pushed; add commits instead.
- When CI is green and the PR has its first approval, announce it per `announce` (below).

### 10. Report

End every run with a short block: capacity used, the issue picked (or why none), the triage verdict, and the PR or close made, each as a link. Nothing else.

## Announcing

`announce.mode`:

- `draft` (default): print the message for the user to post. Use when a person is at the keyboard.
- `post`: post it to `announce.channel` yourself. Only set this once the user has said so; it posts under whoever's account runs Reaper.
- `off`: don't announce.

The message is one line: the PR link, its title, and the code owners who need to approve.

## Hard rules

- Never pick an issue that is assigned, or lacks `labels.pick`.
- Never close a human-filed issue.
- Never widen scope past the issue. Anything else you notice becomes a comment on the issue, not part of the PR.
- Never write anything in `--dry-run` or `--status`.
- Never commit secrets, evidence files, or anything the repo's instructions forbid agents to read.
