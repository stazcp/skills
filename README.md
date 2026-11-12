# Staz's skillz

Claude Code plugins I use every day, for personal and work projects.

```
/plugin marketplace add stazcp/skillz
/plugin install orc@staz
/plugin install brain@staz
/plugin install review-pr@staz
/plugin install presentation@staz
/plugin install standup@staz
/plugin install reaper@staz
```

## orc

orc is short for orchestrator.

Your main session keeps doing the work. It hands a piece to a tier agent only
when that pays off:

- the piece would fill your context with output you won't need again, such as a broad search or a log dig
- it needs a cheaper model, or a stronger one, or a different effort level
- it splits into independent pieces that can run in parallel

When a piece qualifies, orc asks you first and recommends an option. You can
also ask for a handoff at any time: "hand this off", "send it to tier-fast",
"fan this out".

### Use it

| | |
|---|---|
| `/orc` | Turn handoffs on for this session |
| `/orc <task>` | Get handoff options for one task right away |
| `orc off` | Back to a plain session |
| `claude --agent orc:orchestrator` | Handoffs on from the first turn, for the whole session |

`/orc` is the easy way to try it, because nothing changes until you ask.
`--agent orc:orchestrator` puts the rules in the system prompt, so they hold better
over long sessions.

### Tiers

| Agent | Model, effort | For |
|---|---|---|
| `orc:tier-cheap` (experimental) | Haiku | Lookups, and mechanical commands where the exact command is given. Never edits. |
| `orc:tier-fast` | Sonnet, low | One or two files, an obvious change, a summary |
| `orc:tier-strong` | Opus, medium | Several files, debugging with a repro, tests |
| `orc:tier-max` | your session's model, high | Unclear goal, no repro, or high stakes |
| `orc:tier-strong-wide`, `orc:tier-max-wide` | as above | Same, but may fan out to lower tiers and to parallel searches |
| `orc:tier-all-out` | your session's model, max | Only when you ask for it |

Start your session on Opus, or on Fable if your account has it. Each subagent
starts cold, with roughly 15–25k tokens of context, so orc keeps small and
medium work in your session.

## brain

Save notes to your Obsidian vaults, and recall them, from inside a session.
It handles more than one vault, for example one per job and a personal one,
and won't write one vault's notes into another.

| | |
|---|---|
| `/brain <text>` | Save a note. "Save that" works, because it reads the conversation |
| `/brain ? <query>` | Answer from your notes, citing each note it used |
| `/brain session` | Write up this conversation: decisions, findings, open questions, links |
| `/brain @<vault> …` | Use a vault other than the default |
| `/brain --setup` | Find your vaults and write a spec for each |

Each vault has a short spec at `~/.config/brain/<name>.md` (or under
`$BRAIN_HOME`) that sets its path, what belongs in it, how files are named and
filed, and whether it commits to git. `~/.config/brain/active` holds the
default vault's name; an `active.local` next to it wins, for a machine that
should default to a different vault. Run `/brain --setup` to write the specs, or copy
[`vault-template.md`](plugins/brain/skills/brain/vault-template.md).

If a vault's spec names a git remote, brain pushes after each commit, but only
once [gitleaks](https://github.com/gitleaks/gitleaks) finds no secrets in it.
Without gitleaks it commits and doesn't push.

It isn't tied to Obsidian. Any folder of Markdown notes works, such as a
Logseq or Foam graph, or a plain folder in a git repo. `--setup` only finds
Obsidian vaults by itself, so give it the folder's path for anything else. If
your tool doesn't read `[[wikilinks]]`, set the link style in the spec's
Conventions section.

## review-pr

Review someone else's PR with an agent at your side, including code in a
language you don't read well.

`/review-pr <pr>` explains what the PR does in plain terms, with a glossary in
a language you do know. It reviews the PR against the repo's own docs and your
notes (through `brain`, if you have it), and has a separate agent try to break
each finding before you see it. Each finding comes with a what-could-go-wrong
story, a trace you can click through, and the author's likely pushback. It
drafts the review in your voice and posts nothing until you say so.

## presentation

`/presentation <source>` turns a dense doc, page, issue or topic into a short
animated step-through HTML explainer: 8 to 12 scenes, one diagram each, built
only from the source, with Confirmed / Likely / Not known chips so the reader
can see what is solid. It writes one self-contained file and never publishes.

## standup

`/standup` builds a Yesterday / Today / Blockers report from your real GitHub
activity (PRs, issues, commits). Plain text to read out or paste; it never
posts.

## reaper

`/reaper` runs issues a human has labelled for it through a bot you can tag on GitHub. Each run is one tick: it asks the bot whether each issue is still worth doing, closes stale AI-generated ones (human-filed ones go back to their author), tags the bot to fix the rest with a PR that says no human has read it, and starts nothing new while too many are in flight. It writes no code itself. Start with `/reaper --dry-run`; it needs a per-repo config (see `config.example.yaml`).

## Private settings

Some skills read optional private settings from one folder: `$SKILLZ_CONTEXT`,
or `~/.config/skillz` when that is unset. Every file in it is optional; with
none, the skills fall back to safe defaults.

| File | Read by | Holds |
|---|---|---|
| `prefs.md` | standup | `github_user`, `gh_orgs`, your main focus |
| `notes.md` | standup | standing input GitHub can't see: non-PR work, blockers, time off |
| `presentation.md` | presentation | default output folder, how to save there, audience default |
| `reaper/<owner>-<repo>.yaml` | reaper | which issues to pick, caps, excluded paths, where to announce |

Keep the folder wherever you keep private config (a dotfiles repo, say) and
symlink it to `~/.config/skillz`. `brain` keeps its vault specs separately, in
`~/.config/brain`.

## License

MIT
