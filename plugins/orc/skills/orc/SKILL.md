---
name: orc
description: >-
  Turn on tier handoffs and output-volume routing in this session: small-output
  actions stay here, anything returning more than a screen goes to a tier agent
  or a Workflow under a return contract, costly-mistake work gets a refuter;
  routes silently, asks only for costly or ambiguous choices, and hands off on
  demand
---

# orc

Read `../../agents/orchestrator.md`, relative to this skill's base directory, now,
in full, and follow it for the rest of this session. It is the reference;
don't restate it.

Adaptations, because this session was not launched as the orchestrator:

- **Tools.** You keep every tool you have.
- **Tiers.** orc:tier-cheap, orc:tier-fast, orc:tier-strong, orc:tier-max,
  orc:tier-strong-wide, orc:tier-max-wide and orc:tier-all-out are available
  through the Agent tool, as is `fork`.
- **Workflow.** The Workflow tool is available alongside the tiers when the
  host offers it, with the same tiers as `agentType`. Standing authorization
  comes from the user's CLAUDE.md: check only what is already loaded, once,
  and remember the answer. If no CLAUDE.md is in context, treat it as no
  standing authorization; a Workflow then needs the user's yes per task.
- **Top tier.** Your own model sets the top tier, exactly as a launch model
  would. On a session running below Opus, dispatch orc:tier-max and the
  -wide and all-out variants with `model: "opus"`.
- **Existing context.** Whatever this conversation already holds stays; the
  rules apply to new pieces from here on. Do not re-read or summarise earlier
  work to catch up, and remember that `fork` copies all of it.

Say once, in one line, that orc routing is on. Then carry on with the work.

`/orc <task>` means "hand this off": an Agent on the tier you pick, no
question. If the task is an inline-by-rule action (push, commit, PR, `gh`,
Slack, a small edit), do it here and say in one line that it stayed inline.
Ask only when the rules themselves say to: a Workflow without standing
authorization, the first dispatch on a model stronger than the session's, or
a shape that could go either way where the difference matters.

"orc off" ends it: say so in one line and behave as a plain session for the
rest of the session. "orc on" restores it. Nothing persists; a new session
starts plain.

`claude --agent orc:orchestrator` at the shell is the same thing from the first turn.
