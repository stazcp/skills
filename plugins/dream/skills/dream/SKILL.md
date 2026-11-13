---
name: dream
description: Consolidate and organize a body of memory notes the way sleep consolidates a day: cluster by topic, merge near-duplicates, resolve contradictions, retire superseded entries, make dates absolute, add links and an index, all from a plan the user approves first, with a backup taken before anything is touched. Use when the user says /dream, "consolidate my memories", "clean up and organize these notes", "add a table of contents to my notes", or "tidy up my memory". Works on Claude's auto-memory (`memory`), a brain vault (`@<vault>`), or any folder or file of Markdown (`<path>`).
argument-hint: "[memory | @<vault> | <path>]... [--plan-only]"
---

# Dream

Sleep adds no new memories; it sorts the ones already there, keeps what
repeats, drops what contradicts newer experience and links what belongs
together. This skill does that to a folder of Markdown notes. It reads
everything, works out what has merged, aged out or contradicted something
newer, shows a plan, and applies only what the user approves. It learns
nothing new and writes no fact it didn't read.

**This file is the engine and holds no proper nouns.** Which vault, where it
lives, how it commits, where superseded notes go: all of that is in the
target's spec, or in the target's own conventions. When this file and a spec
disagree, the spec wins.

A sibling of `/brain`, not a mode of it: brain saves and recalls in one
vault and never touches auto-memory; dream reorganizes whatever collection it
is pointed at, one at a time, and moves nothing between them.

## 1. Targets — resolve these before anything else

| Argument | Target | How to find it |
|---|---|---|
| nothing | ask | AskUserQuestion: which collection to dream, offering `memory`, each vault found below, and "a path" |
| `memory` | Claude's auto-memory for this project | the directory the session names (`~/.claude/projects/<slug>/memory/`, index `MEMORY.md`); if none is named, `ls -d ~/.claude/projects/*/memory` and ask which |
| `@<name>` | a brain vault | spec at `${BRAIN_HOME:-~/.config/brain}/<name>.md` or `<name>/brain.md`; the default vault's name is in `active.local`, else `active`, in that home |
| `<path>` | a folder or one file of Markdown | as given; a folder is read recursively |
| `--plan-only` | modifier | write the plan, skip the backup and the question, apply nothing |

Several targets may be given. Each is dreamed on its own: its own read,
plan, backup, apply and report. **Nothing read from one target informs,
links to or enters another.**

For a vault, read its spec in full before reading a note; its Path, Private,
Git, Sandbox, Conventions and Filing (Index, Archive, Inbox) lines each bind
a step below. A Path that doesn't exist on this machine: stop and say so;
don't create it.

Skip while reading: `.git/`, `.obsidian/`, `node_modules/`, anything an
ignore file at the target root names (`.cursorignore`, `.claudeignore`), and
files that look like secrets (`.env*`, `*.pem`, `*.key`). Never read those to
"check" them.

## 2. The dream, step by step

Steps 2.1–2.5 write nothing into the target. The first write is 2.6, after a
yes.

### 2.1 Read everything

Read every file in the target in full, not a sample. Build one table: path,
title, date, kind (frontmatter `type` or folder), the claims it makes, every
file, function, flag, PR, issue or branch it names, and what it links to. For
auto-memory, add its `MEMORY.md` line.

Date a note by, in order: a frontmatter date; its latest `## YYYY-MM-DD`
section; `git -C <target> log -1 --format=%as -- <file>` when the target is
in git; else the file's mtime (`stat -f %Sm -t %F <file>`).

### 2.2 Verify claims (read-only)

A note that names something checkable keeps its claim only if the thing is
still so. Check against the repo or tool the note is about, never by memory:

| The note names | Check |
|---|---|
| a file or folder | `test -e <path>` |
| a function, type, flag, env var, setting | `grep -rn '<name>'` in that repo (quote the pattern) |
| a PR or issue | `gh pr view <n> --json state,mergedAt,title` / `gh issue view <n> --json state,title` |
| a branch | `git branch -r --list '*<name>*'` |
| a command or tool | `command -v <tool>` |

| Outcome | Plan entry |
|---|---|
| still so | keep |
| changed (PR merged, file gone, flag renamed) | **retire** or **supersede**, with what changed and the date you checked |
| can't check here (no repo, no network, needs credentials) | keep, mark `status: unverified`; never guess |

Verification posts nothing, comments on nothing, edits nothing.

### 2.3 Cluster and find the changes

Group notes by topic. Within a group, look for each of these:

| Pattern | Proposed change |
|---|---|
| Two notes say the same thing | **merge**: one survives with both sets of facts and the earlier date; the other is retired |
| Two notes disagree | **resolve**: the newer wins; the survivor says in its body what it supersedes and from when; the older is retired |
| A note is dated, done, or verified gone | **retire** (how depends on the target: §4) |
| N notes report the same kind of fact or mistake | **pattern**: one note names the root cause and links the N; in auto-memory, a `feedback` memory |
| "yesterday", "last week", "now", "recently" | **absolutize** from the note's own date; no anchor → leave it and flag it |
| Related notes don't link | **link**: `[[basename]]` both ways, where the target's conventions use wikilinks; `[Title](file.md)` where they don't |
| Wordy | **tighten**: fewer words, every fact, number, date, name and caveat kept |
| Collection past the threshold (§5) | **index** |

Tightening never changes a fact. If a merge would lose a date, a number, a
name or a caveat, it isn't a merge: keep both and link them instead.

### 2.4 Back up, then write the plan

1. Make the backup directory, outside every git repo:
   `~/.local/state/dream/<label>/<YYYYMMDD-HHMMSS>/` where `<label>` is
   `memory-<slug>`, the vault's name, or the path's basename. Copy the target
   into `before/` (`cp -R`). A vault's git history is not the backup; the
   copy is. If the sandbox blocks the copy, run that one `cp` unsandboxed and
   say so. Never back up into the target itself. `--plan-only` skips the
   copy, since nothing in the target will change; the plan still goes in
   that directory, and its Backup line says `none (plan only)`.
2. Write `plan.md` next to `before/` with the Write tool, not a shell
   redirect (the Bash sandbox may not reach that directory), in the shape in `plan-template.md`:
   one numbered line per change (merge, resolve, retire, pattern,
   absolutize, link, tighten, rename, index), each with the files, the
   reason and, for a retire, how (archive / mark / delete).
3. Show a compact summary in the chat: counts per kind, then every retire
   and every index change in full, then the rest as one line each. Over 25
   changes, the chat shows the counts and the retires; the file holds all.

### 2.5 Confirm

AskUserQuestion, one question, three options: **apply all**, **apply
selected** (they name the numbers), **plan only**. A second question asks
whether to write a dream journal (§2.8). No yes, no writes; `--plan-only`
skips the question and stops here with the path of `plan.md`.

### 2.6 Apply

In this order, so links point at files that exist: merges and resolves,
retires, patterns, dates, links, tightening, renames, then the index. Write
with the Edit and Write tools; move with `git mv` in a git target, `mv`
otherwise, and if the sandbox blocks a move, run that one command
unsandboxed and say so. Then check:

- every `[[link]]` resolves to a basename in the target, every
  `[Title](file.md)` to a file;
- every file is in the index exactly once, no index line points nowhere;
- `diff -rq <backup>/before <target>` lists only the planned changes.

Anything else found at this check is undone from `before/`, not patched.

### 2.7 Commit (a vault whose spec names git)

- Commit after the apply, one commit, with the spec's commit rule; check it
  landed with `git -C <vault> log -1 --format=%h`. No git in the spec: no git.
- Push only when the spec names a remote **and** the branch has an upstream
  (`git -C <vault> rev-parse --abbrev-ref @{u}`), with a plain
  `git -C <vault> push`: no other remote, no refspec, never `--force`.
- **Pre-push key check first, every time:**
  `gitleaks git <vault> --log-opts="@{u}..HEAD" --redact --exit-code 1`. Any
  finding, gitleaks missing, or a scan error: don't push; tell the user the
  rule and file (redacted), never the value. Clean scan: push, then
  `git -C <vault> status -sb` must show no "ahead".
- A commit or push the sandbox, a classifier or signing blocks is not worked
  around: give the user the exact command. Never turn signing off, never add
  a remote, never change visibility or collaborators.

A plain folder or file under git that isn't a vault: don't commit. Say the
tree is dirty and let the user commit.

### 2.8 Report and journal

Report as in **After writing**. If the user asked for a journal, write one in
the shape in `plan-template.md`: what changed, what was left alone and why,
what couldn't be verified, and open questions for the user. Where it goes:

| Target | Journal |
|---|---|
| vault | a note in the spec's Inbox folder (else the vault root), `YYYY-MM-DD Dream journal.md`, filed by the spec's Conventions and committed with the change |
| auto-memory | `<backup>/journal.md`; never a memory file |
| path | `<backup>/journal.md` |

## 3. Rules for every target

- **Plan, then yes, then write.** No file in the target changes before the
  user approves the plan. Not a link, not a date.
- **Backup before the first write**, and say where it is in the report.
- **Never invent.** Merging combines what was written; it infers nothing,
  fills no gaps, and reads nothing into silence.
- **Verified, or marked.** A claim that couldn't be checked gets
  `status: unverified`, not a guess at the truth.
- **No secrets.** Never write a token, key, password or connection string,
  not even one found in a note being merged: drop it and say so.
- **Never touch `.obsidian/`.** Read its config; never write it.
- **One-way out.** What was read stays in the target, the backup, the plan
  and this conversation. Nothing goes to a repo, Slack, GitHub, Notion, an
  artifact or a work-facing output. For a vault marked **private**, even the
  plan summary in the chat names files, not their contents.
- **No crossing.** `memory` never writes into a vault; a vault never writes
  into auto-memory; notes never copy between vaults. Dreaming two targets in
  one run means two dreams.
- **Preserve the format exactly**: the frontmatter keys, the index line
  shape, the filename convention. Dream reorganizes, it doesn't restyle.
- **People by role only** where the spec says so; a merge never adds a name
  the originals didn't carry.
- **A blocked write, move, commit or push** gets the user the exact command,
  not a workaround.

## 4. Per-target rules

| | auto-memory | brain vault | folder or file |
|---|---|---|---|
| format | one fact per file, frontmatter below; `MEMORY.md` index | the spec's Conventions; else match a neighbouring note | match a neighbouring file |
| retire: superseded | delete the file **if** every fact survives in the merge; else mark `status: superseded`, link the survivor | move to the spec's **Archive** folder if it names one; else stay in place with `status: superseded` and a link to the replacement in the body | mark `status: superseded` (frontmatter if the file has it, else a first line) and link the replacement |
| retire: verified wrong | delete, listed in the plan with what was checked | archive or mark, as above; say what was checked in the body | mark, as above |
| delete allowed | only the two rows above, only after backup, only from the plan | never | never |
| index | group `MEMORY.md` under topical `##` headings (§5) | the spec's **Index** note, else a map-of-content note per folder past the threshold | a TOC at the top of a long file; an `index.md` for a folder |
| commit | none | the spec's Git rule (§2.7) | none |
| journal | `<backup>/journal.md` | the spec's Inbox | `<backup>/journal.md` |

### Auto-memory format (keep it exactly)

Each memory file:

    ---
    name: <short title>
    description: <one line, what it's for>
    metadata: {type: user | feedback | project | reference}
    ---
    <the fact, in a line or two>

    **Why:** <for feedback and project memories>
    **How to apply:** <for feedback and project memories>

    Related: [[other-memory-name]]

`MEMORY.md` has no frontmatter and one line per memory:
`- [Title](file.md) — <hook: when it matters, in a few words>`. Merging two
memories means one file survives with both facts (the clearer name wins;
the older `type` stays unless both agree), the other file is removed, and
its `MEMORY.md` line is removed or folded into the survivor's. `MEMORY.md`
stays under **200 lines and 25 KB**; that is the load limit, not a target.

## 5. Indexes

A collection earns navigation when a reader can no longer hold it in one
look. Defaults; a spec's Index line overrides them:

| Collection | Add or rebuild an index when | Shape |
|---|---|---|
| `MEMORY.md` | more than 30 entries, or any entry is hard to find by scanning | `## <Topic>` headings, entries grouped under them, still one line each, same line shape, no frontmatter; an `## Other` group only for a true leftover |
| a vault folder | more than 15 notes and no index note names them | one map-of-content note (`<Folder>.md` or the spec's name) with a one-line `[[link]] — hook` per note, grouped by topic |
| one file | more than 150 lines or more than 8 `##` headings | a `## Contents` list of `[heading](#anchor)` links right under the title |

**An index is kept, not just made.** Every merge, rename, retire or new note
in the apply step updates the index in the same step, and the 2.6 check
fails on an index line that points nowhere or a file the index doesn't name.
A `MEMORY.md` entry moves between groups when its topic changes; a group
that empties is removed. When the index is itself a note the spec names
(root index, area Home notes), edit that note; don't make a second one.

## After writing

One line per target: what was dreamed, counts (merged / resolved / retired /
patterned / linked / indexed, and deleted for auto-memory), where the backup
is, and for a vault the commit hash and the push result: `pushed`,
`push blocked: <reason>`, or `no remote`. For example:
`memory: 38 files → 31; 5 merged, 2 retired (deleted, listed), 1 pattern, MEMORY.md grouped under 6 headings; backup ~/.local/state/dream/memory-<slug>/20260101-073000/.`
or `work: 212 notes; 9 merged, 4 archived to Archive/, 2 unverified, Research/Research.md rebuilt; commit a1b2c3d, pushed.`
Then the open questions, if any, one line each.
