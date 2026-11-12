---
name: reaper
description: "Run a curated backlog of small issues through an implementer bot you can tag on GitHub (a PR-review bot that also writes fixes). Reaper decides what goes in and how fast: it asks the bot whether each labelled issue is still worth doing, closes or hands back the stale ones, tags the bot to fix the rest, and paces new work by how many PRs are waiting for review. It writes no code itself. Use when the user says /reaper, \"run reaper\", or runs it on a loop."
argument-hint: "[--dry-run] [--issue <n>] [--status]"
---

# Reaper

A human curates small issues by labelling them. Reaper runs them through an implementer bot: it asks the bot to triage each one, acts on the verdict, tags the bot to implement the ones still worth doing, and keeps the PRs moving toward a human approval. The human who approves becomes accountable for the change. Reaper never writes code.

Every run is one **tick**: advance everything already in flight by one step, then start at most one new issue if there is capacity. Run it by hand, or on `/loop`. All state lives on GitHub (labels, assignees, comments, PRs), so a run can stop anywhere and the next one picks up.

## Modes

- `/reaper`: one tick.
- `/reaper --dry-run`: work out the tick and print every action it would take. **Write nothing.** Use this for the first runs on a repo.
- `/reaper --issue <n>`: start issue `<n>` now instead of picking (still subject to capacity and every check).
- `/reaper --status`: one line per in-flight issue with its stage and link. Read-only.

## Config

Run from inside the target repo's checkout. Find `<owner>/<repo>` with `gh repo view --json nameWithOwner`, then read `<context>/reaper/<owner>-<repo>.yaml`, where `<context>` is `$SKILLZ_CONTEXT` or `~/.config/skillz`. `config.example.yaml` next to this file lists every key. **No config file means stop:** say where it goes and point at the example. Never guess a label, handle or cap.

Read the repo's own agent instructions (`CLAUDE.md` / `AGENTS.md`) before writing anything on GitHub, and follow them over this file, for example any footer every comment must carry.

Reaper's comments go out under the account `gh` is logged in as. The bot treats that person as the one asking, so it must be someone the bot accepts change requests from.

## Stages

An issue is **in flight** when it carries `labels.pick` and is assigned to `identity.assignee`. Its stage is read from GitHub each tick, never remembered:

| Stage | How to tell | This tick |
|---|---|---|
| triage asked | Reaper's triage comment, no bot reply after it | wait |
| triage answered | bot reply with a `Verdict:` line | act on it (below) |
| fix asked | Reaper's fix comment, no PR yet | wait; after `caps.stuck_hours` with no bot activity, report it |
| PR open | an open PR that closes the issue | look after the PR (below) |
| done | PR merged, or issue closed | unassign; no longer in flight |

### Triage

Ask the bot on the issue, in one comment:

> `<implementer.handle>` Before anyone works on this: is it still valid against the current default branch? Check whether the code it names still exists, whether it still reproduces, and whether a merged PR already fixed it. **Don't change anything.** End your reply with exactly one line: `Verdict: valid`, `Verdict: stale — <evidence>` or `Verdict: not worth doing — <reason>`.

Then act on the verdict:

- **valid:** run the shallow gate, then ask for the fix.
- **stale / not worth doing, and the issue is AI-generated:** close it as not planned, with a comment quoting the verdict line and linking the bot's reply.
- **stale / not worth doing, and a human filed it:** don't close it. Comment that the bot judged it stale (link the reply), remove `labels.pick`, unassign. The person who filed it decides.
- **no Verdict line, or more than one:** treat as unclear. Comment asking the bot for just the line, once; if it's still unclear next tick, hand the issue back to the user in the report.

An issue is AI-generated when its author is in `ai_generated.authors`, it carries a label in `ai_generated.labels`, or its body contains one of `ai_generated.body_markers`. When unsure, it is human-filed.

### Shallow gate

Judge from the issue and the bot's triage reply. It fits only if the expected change is under `limits.max_diff_lines`, stays in one area or service, touches nothing in `limits.excluded_paths`, and has a repro or acceptance criteria. If it fails: comment why in a sentence or two, specific enough to teach the curator ("needs a schema change in X"); remove `labels.pick`, add `labels.rejected`, unassign.

### Asking for the fix

One comment on the issue:

> `<implementer.handle>` Please open a PR that fixes this. Keep it to this issue and under `<max_diff_lines>` changed lines; don't touch `<excluded_paths>`. Reproduce it first, and show the fix works: a test that fails before and passes after, and for any UI change screenshots or a video. Start the PR description with this paragraph, verbatim:
>
> ⚠️ **AI-generated code and description. No human has read this PR.** It was written from #<issue>. By approving it you take on the responsibility the author normally carries: you are accountable for this change as if you had written it.

### Looking after the PR

Find it with `gh pr list --state open --search "<issue number> in:body"` and confirm it closes the issue. Then, each tick:

1. **Labels:** add `labels.pr` and `pr.extra_labels` if missing.
2. **Banner:** if the description doesn't start with the banner, prepend it. Edit surgically: fetch the live body and put the banner in front, never rewrite the rest.
3. **Shallow re-check on the real diff** (`gh pr diff --name-only`, `gh pr view --json additions,deletions`). Over the limit or touching an excluded path: comment on the PR and the issue, add `labels.rejected`, leave the PR as a draft, and hand it to the user in the report. Don't close it; a human decides.
4. **Ready:** once CI is green and the description has the banner, mark a draft ready (`gh pr ready`), because only a ready PR waits for reviewers.
5. **Announce:** once it's ready, green and has its first approval, announce it per `announce` (below), once.
6. **Stuck:** red CI or open review threads with no bot activity for `caps.stuck_hours`: comment `<implementer.handle> please fix the failing checks and open threads` once; if still stuck a tick after that, hand it to the user.

Never push to the PR's branch, approve it or merge it.

## Capacity

Count in-flight issues. At `caps.max_in_flight` or above, start nothing new this tick. Also stop at `caps.daily_max` new issues started per local day. Advancing work already in flight is never capped.

## Picking

```bash
gh issue list --label <labels.pick> --state open --search "no:assignee" --json number,title,labels,author,createdAt
```

Keep issues that also carry one of `pick.types` and none of `pick.exclude_labels`; oldest first. Assign it to `identity.assignee` (that's the claim), then ask for triage. If `project` is configured, set its status to `project.in_progress`.

## Announcing

`announce.mode`: `draft` (default) prints the one-line message for the user to post; `post` posts it to `announce.channel` (only once the user has said so, since it posts under their account); `off` skips it. The line is the PR link, its title, and the code owners who must approve.

## Report

End every tick with a short block: capacity used, one line per in-flight issue (stage, what this tick did, link), and anything handed to the user. Nothing else.

## Hard rules

- Never touch an issue without `labels.pick`, or one assigned to someone other than `identity.assignee`.
- Never close a human-filed issue.
- Never write code, push, approve or merge.
- Never write anything in `--dry-run` or `--status`.
- One comment per purpose: before posting, check the thread for Reaper's own earlier comment with the same purpose, so a re-run never double-posts.
