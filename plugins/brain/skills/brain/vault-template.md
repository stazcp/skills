# Vault spec

Copy this to `~/.config/brain/<name>.md` (or `$BRAIN_HOME/<name>.md`) and fill
it in. The engine (`SKILL.md`) decides how notes are saved and recalled; this
file decides which vault and its house rules. Delete what doesn't apply; the engine
treats a missing section as "match the neighbouring notes".

## Vault

- **Name**: <short label shown in reports> (select with `@<name>`, the spec's filename)
- **Path**: `~/<vault folder>` (use `~`, so it travels between machines)
- **Private**: yes | no
- **Git**: none | git on `<branch>`, remote: none | `<remote name>` =
  `<private repo url>` (the branch must track it), commit with
  `git -C <path> add -A && git -C <path> commit -m "<what>"`. Name a remote
  only if the vault already has one; the engine pushes to it after every
  commit, behind its key check, and never adds one.
- **Sandbox**: whether the Bash sandbox blocks writes there
- **Backup**: what already backs it up, if anything (the remote, a sync, a
  scheduled copy)

## What belongs

<the kinds of notes that go here>

## Never here

<what must go to a different vault, and which one>

## Conventions

- **Filename**: <e.g. `YYYY-MM-DD <Title>.md`, or a plain title>
- **Frontmatter**: <keys, or "match the neighbours">
- **People**: <by role only, or no rule>
- **Appending**: <dated `## YYYY-MM-DD` section, or extend in place>

## Filing

- <how folders are chosen; an index note to read first, if the vault has one>
- **Index**: <note(s) to add new notes to>
- **Inbox**: <folder>
- **Archive**: <folder, or none>

## Daily log

On | Off

## Recall

<anything to read first for focus or status questions>
