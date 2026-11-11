# Staz's skills

Claude Code plugins I use every day, for personal and work projects.

```
/plugin marketplace add stazcp/skills
/plugin install orc@staz
/plugin install brain@staz
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

## License

MIT
