---
name: brain
description: Save to and recall from the user's private Obsidian vaults. Use when the user says /brain, "save this to my brain", "note this down", "what do my notes say about X", or "capture this session". `/brain <text>` saves, `/brain ? <query>` recalls, `/brain session` captures the conversation; `@<vault>` picks a vault.
argument-hint: "[@<vault>] <text> | ? <query> | session | --setup"
---

# Brain

The user keeps one or more private Obsidian vaults: often one per workplace
and a personal one that outlives every job. This skill writes clean notes
into the right one and reads them back. Nothing else.

A "vault" is any folder of Markdown notes. Obsidian is the default, not a
requirement: for a vault without `.obsidian/`, skip the Obsidian-only steps
(its daily-notes settings fall back to the defaults below) and follow the
spec's Conventions for link style, using `[[basename]]` only where the spec
allows it or the neighbouring notes already do.

**This file is the engine and holds no proper nouns.** Which vault, where it
lives, how it commits, how it names files: all of that is in the vault's
spec. When this file and a spec disagree, the spec wins.

## 1. Pick the vault — do this before anything else

Specs live in the brain home, `$BRAIN_HOME`, or `~/.config/brain` when that
is unset. A vault called `<name>` has its spec at `<home>/<name>.md` or
`<home>/<name>/brain.md`. The default vault is the name written in
`<home>/active`, a one-line file.

    home="${BRAIN_HOME:-$HOME/.config/brain}"
    ls "$home"/*.md "$home"/*/brain.md 2>/dev/null   # every vault (skip TEMPLATE)
    cat "$home/active" 2>/dev/null                   # the default vault's name

- **`@<name>` given** (`/brain @personal …`): use that vault's spec.
- **No `@`**: use the vault named in `active`. With no `active` file and
  exactly one spec, use that one.
- **Then check the content against the chosen spec's "What belongs" and
  "Never here" sections.** If it belongs in a different vault (a job search
  note while the work vault is active, say), switch to that vault and say so
  in the one-line report. If it's genuinely unclear which, ask. **Never write
  one vault's material into another, and never copy notes between vaults.**
- **No spec found** (no brain home, no specs, or `active` names one that
  doesn't exist): say so, list the vaults that do exist, and offer
  `--setup`.

Read the chosen spec in full. Everything below that says "the spec" means
that file.

### Path on this machine

The spec's **Path** is written with `~` so it travels between machines.

- **It exists:** carry on silently.
- **It doesn't** (new machine, cloud sync not finished, vault not cloned):
  stop and say so. Don't create the folder; an empty folder in the wrong
  place is how notes get lost. Offer `--setup`.

### `--setup`

For a new machine or a new vault. Find candidates: any directory under `~`
up to 4 levels deep that holds a `.obsidian/` folder, plus
`~/Library/Mobile Documents/iCloud~md~obsidian/Documents/` on macOS. Show
them next to the specs that exist, and **ask** which spec each one is.
A vault that isn't an Obsidian vault won't turn up here; ask for its path.
Then either fix the spec's Path, or copy `vault-template.md` (next to this
file) to `<home>/<name>.md` and fill it in with the user, asking rather
than guessing each section. If there is no `active` file yet, ask which
vault should be the default and write its name there. Never pick a vault
silently.

Keeping the brain home in a private git repo (and pointing `BRAIN_HOME` at
it) carries the specs to the user's other machines; suggest it, don't do it.

## 2. Modes

Parse what's left of the argument after any `@<name>`:

| Argument | Mode |
|---|---|
| `? <query>` | **Recall**: search and answer |
| `session` | **Capture**: write up this conversation as one note |
| `--setup` | **Setup**: see above |
| anything else | **Save**: turn the text into a note |
| nothing | Ask what to save, and offer `session` |

For **Save**, the text may be terse or say "this" or "that". Read it against
the conversation just before it and save what was meant, not the literal
words.

## 3. Rules for every vault

- **Writing and committing follow the spec.** If its Sandbox line says the
  Bash sandbox blocks writes there, write through the Write and Edit tools
  and run git unsandboxed. If its Git line names a commit rule, commit after
  every change (the save and its daily-log line together) and check that it
  landed with `git -C <vault> log -1 --format=%h`. If the spec says no git,
  don't run git.
- **Push only when the spec names a remote.** If the spec's Git line names a
  remote **and** the branch has an upstream
  (`git -C <vault> rev-parse --abbrev-ref @{u}` succeeds), push after every
  commit, behind the key check below. Otherwise commit only. Push only to
  that configured upstream, with a plain `git -C <vault> push`: no other
  remote, no refspec, never `--force`. Never add a remote, change the repo's
  visibility, or add collaborators, apps, deploy keys or Actions.
- **A blocked commit or push isn't worked around.** If the sandbox, a
  classifier or commit signing blocks it, give the user the exact command to
  run. Never turn signing off.
- **Pre-push key check: mandatory before every push.**
  1. Scan the unpushed commits and the files just written:
     `gitleaks git <vault> --log-opts="@{u}..HEAD" --redact --exit-code 1`
     and `gitleaks dir "<file>" --redact --exit-code 1` for each file.
  2. **Any finding, gitleaks missing, or a scan that errors** (any non-zero
     exit): don't push. Keep the commit local and tell the user the kind of
     finding (the gitleaks rule, redacted, never the value), the file, and
     that the push is blocked until it's resolved.
  3. Taking a secret out of an unpushed commit means amending or rewriting
     local commits. Tell the user and let them decide; never do it silently.
  4. Push only on a clean scan, then check that
     `git -C <vault> status -sb` shows no "ahead".
- **Never touch `.obsidian/`.** Read its config, don't write it.
- **One-way out.** Nothing read from a vault goes to a repo, Slack, GitHub,
  Notion, an artifact or a work-facing output until it has been cleaned of
  personal remarks and DM excerpts. Recall answers stay in this conversation.
  If the user then asks to use one somewhere else, clean it first and say
  what you cut. A vault the spec marks **private** is stricter: its content
  doesn't leave at all without the user asking in so many words. The vault's
  own remote, when the spec names one, is the vault itself, not "out":
  pushing there isn't leaving.
- **People by role only** where the spec says so ("a research engineer on
  an enterprise team"), never by name.
- **No secrets.** Never write tokens, keys, passwords or connection strings
  into a note, even ones that appeared in the conversation. The pre-push key
  check backs this rule up; it doesn't replace it.
- **Separate from auto-memory.** `/brain` doesn't read from, write to or
  mirror `~/.claude/projects/*/memory`. That is Claude's own memory. Save to
  one or the other, never both.
- **Never delete.** Superseded notes move to the spec's archive folder if it
  names one; otherwise they stay and are marked superseded.

## 4. Note conventions

The spec's **Conventions** section decides filename, frontmatter and folders.
Where it is silent, match a neighbouring note: read one before writing.

- **Basenames must be unique**, because wikilinks resolve by basename. Check
  with `find <vault> -name '<name>.md'`. Leave out `[ ] # ^ | \ / :`.
- **Body**: a `# Title`, then the substance in short sections or bullets.
  Link related notes as `[[basename]]`, and PRs and issues as full URLs.
- **Dates are absolute** (`2026-10-25`), never "yesterday".
- **Status** (`status: unverified | provisional | superseded`) only when one
  applies. A superseded note links its replacement in the body.

## 5. Filing (automatic, don't ask)

1. **Append before creating.** Grep for an existing note on the same topic
   (`grep -rliF '<key term>' <vault> --include='*.md'`, quoting the glob). If
   one fits, extend it the way the spec says (a dated `## YYYY-MM-DD` section
   by default) rather than making a near-duplicate.
2. **Pick the folder** by the spec's filing rules. If it points at index
   notes inside the vault (a root index, area Home notes), read those: the
   vault's own description of itself beats any guess. Otherwise list the
   folders (`find <vault> -maxdepth 2 -type d -not -path '*/.*'`) and choose
   by topic, then by kind.
3. **Nothing fits?** Use the spec's inbox folder. Don't invent a new
   top-level folder for one note.
4. **Link it from the index** the spec names, if any.
5. **Link, don't copy status.** Don't copy ticket statuses or task lists into
   notes; link the ticket or board. A note records decisions, findings and
   context, not status a board already tracks.

### Running logs (progress, gaps, trackers)

For anything tracked over time, keep **one log note per subject** next to
the plan it belongs to, and add to it:

- A **tracker** is a table, newest row last, one row per session.
- A **gaps** note lists *patterns*, not incidents. When a mistake repeats,
  bump the existing pattern's count and date instead of adding a line.
  Patterns that stop recurring move to a "Fixed" section.

## 6. Daily log

Only if the spec turns it on. Every Save and Capture then appends one line
to today's daily note.

- **Location and format**: read `<vault>/.obsidian/daily-notes.json`. If it
  sets `folder` or `format`, use them; otherwise Obsidian's defaults,
  `<vault>/YYYY-MM-DD.md` at the root, which is the file Obsidian's "Open
  today's daily note" opens.
- **Create it if missing**, with frontmatter `date: YYYY-MM-DD` and
  `tags: [daily]`, then a `# YYYY-MM-DD` heading.
- **The line**, appended at the end:
  `- HH:MM saved [[basename]]: <one-line gist>` (or `appended to`, or
  `captured session`), local time from `date +%H:%M`.

## 7. Recall: `/brain ? <query>`

1. Search the **chosen vault only**. Use `find <vault> -iname '*<term>*'`
   and `grep -rniF '<term>' <vault> --include='*.md'`, plus synonyms and
   related PR or issue numbers. Skip `.obsidian/` and `.git/`. Search another
   vault only if the user names it (`@<name>`), and never mix two vaults in
   one answer without saying which claim came from which.
2. Read whatever the spec's **Recall** section says to read first (a focus
   note, a board). Then read the hits that matter.
3. Answer from them, citing every note you used as `[[basename]]` or its
   path. Give each claim's date, because older notes may be superseded. When
   two notes disagree, say so and give the newer one's view.
   **Live status:** when a note says status lives on a board or tracker, run
   the read-only `gh` query it gives (or `gh issue list` /
   `gh project item-list`), answer from the live data and cite the URL.
   Never comment on or edit anything on GitHub.
4. **If the vault doesn't cover it, say so plainly.** Don't dress general
   knowledge up as recall. You may answer separately, labelled as not from
   the vault.

Recall writes nothing and commits nothing.

## 8. Capture: `/brain session`

Write up this conversation as one note, filed like any other:

- `## Decisions`: what was decided, and why, in a line each.
- `## Findings`: what was learned or verified, with evidence links.
- `## Open questions`: what is unresolved, and who or what can answer it.
- `## Links`: PRs, issues, artifacts and related `[[notes]]`.

No transcript dumps, no play-by-play of tool calls. Leave out an empty
section. If this session already wrote a capture note, append a new dated
section to it rather than writing a second note.

## After writing

One line: which vault, what was written, where, the commit hash if the
vault commits, and the push result: `pushed`, `push blocked: <reason>`, or
`no remote`. For example: `work: saved [[2026-10-22 Cache eviction choice]]
to decisions/, logged in 2026-10-22.md, commit a1b2c3d, pushed.`
or `personal: updated Career/Interview/Prep/Gaps.md (no git).`
