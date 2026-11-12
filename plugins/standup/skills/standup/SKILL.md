---
name: standup
description: "Build a short Yesterday / Today / Blockers report for a standup meeting, on demand, from your real activity on GitHub (PRs, issues and commits). Plain text to read out or paste; it never posts anywhere. Use when the user asks for their standup, standup notes, or what to say at standup."
argument-hint: "[--since <YYYY-MM-DD>]"
---

# Standup report

## What this skill is

An on-demand report for an actual standup meeting, run when one is about to
happen. The user reads it out or pastes it into the meeting chat. It is
**built from evidence** — PRs, issues and commits — and it never invents a
line the evidence does not support.

**It never posts.** No Slack message, no draft, no clipboard write, no file.
The report is printed in the terminal and that is the whole deliverable. If
the user then asks to send it somewhere, that is a separate request: load the
chat-voice skill the context names and ask before sending.

Your context folder is `$SKILLZ_CONTEXT`, or `~/.config/skillz` when that is
unset. Read `<context>/prefs.md` for identity (`github_user`, `gh_orgs`) and
the user's main focus, and `<context>/notes.md` for standing input GitHub
cannot see: non-PR work, blockers, OOO. `notes.md` wins over anything you
infer, but never over verified GitHub state. A missing file means "this
context has none"; say so in one line and carry on. With no `github_user`,
use `gh api user -q .login`; with no `gh_orgs`, don't scope by org.

## 1. Window

Run plain `date` (machine timezone, never a `TZ=` override).

- **Yesterday** means since the start of the previous working day. On Monday
  that is Friday, and the weekend is included.
- `--since <YYYY-MM-DD>` overrides the start, for a standup after time off.

## 2. Evidence

All via `gh`, scoped to `org:<gh_orgs>` when it is set, so personal repos never appear. Run
the searches together:

```bash
gh api "search/issues?q=is:pr+author:<user>+org:<org>+updated:<since>..<today>&per_page=100"
gh api "search/issues?q=is:pr+author:<user>+org:<org>+is:merged+merged:<since>..<today>&per_page=100"
gh api "search/issues?q=is:issue+involves:<user>+org:<org>+updated:<since>..<today>&per_page=100"
gh api "search/commits?q=author:<user>+org:<org>+committer-date:<since>..<today>&per_page=100"
```

Search buckets lie about status — an `updated:` hit may already be merged.
Verify each PR individually before writing:

```bash
gh api repos/<owner>/<repo>/pulls/<n> --jq '"\(.state)\tmerged=\(.merged_at // "-")\tdraft=\(.draft)\tbranch=\(.head.ref)"'
```

- Commit search only sees default branches. Work on a branch shows up through
  its PR; do not report a commit and its PR as two things.
- PRs on the same head branch, or with the same title code, are one piece of
  work and get one line.
- A PR closed unmerged is dropped unless the user's notes say why it matters.
- Reviews done for other people are not standup items unless they ate a real
  share of the day. Ask before including one.

## 3. Sort into three

- **Yesterday** — what actually moved: PRs merged, PRs opened or pushed in a
  meaningful way, issues closed or investigated, non-PR work from `notes.md`.
- **Today** — the next step on what is open: a PR that needs review answered,
  the next move on the main focus, anything `notes.md` names. If today's plan
  is not evident from the evidence, ask the user one question rather than
  guess.
- **Blockers** — only real ones: waiting on a named person, a review that has
  sat for days, a decision someone else owns. Say who. `None.` is a normal
  answer.

Ask at most one batched round of questions, and only for what the evidence
cannot settle. Never invent a blocker, a plan, or a "done".

## 4. Shape

Short and speakable: it should read aloud in about thirty seconds.

```
Yesterday
- Merged the login retry fix (#4812).
- Opened the usage export PR (#4815); it's in review.

Today
- Answer the review on #4815.
- Start the export scheduling work.

Blockers
- Waiting on Sam for the API key rotation.
```

- Three headings, always in this order. One to three lines under each.
- Plain sentences a person would say. The PR number goes at the end in
  parentheses, so the line still reads aloud without it.
- No status tags, no `@handle`, no Slack markup, no emoji, no dates on lines.
- Plain-English outcomes, not a commit log. Bundle rather than list.

## 5. Hand-off

Print the report in one fenced block so it copies cleanly. Under it, one line
naming anything you could not check (auth failed, a search came back empty).
Nothing else — no follow-up offers.

The only write is to `notes.md`: retire a note whose work has shipped, and say
that you did.
