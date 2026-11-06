---
name: orc
description: >-
  Turn on tier handoffs in this session: keep doing the work here, but suggest
  handing a piece to a tier agent (with a recommended option) when this
  context gains little from it or it needs a different model or effort, and
  hand off on demand
---

# orc

Read `../../agents/router.md`, relative to this skill's base directory, now,
in full, and follow it for the rest of this session. It is the reference;
don't restate it.

Adaptations, because this session was not launched as the router:

- **Tools.** You keep every tool you have.
- **Tiers.** orc:tier-cheap, orc:tier-fast, orc:tier-strong, orc:tier-max,
  orc:tier-strong-wide, orc:tier-max-wide and orc:tier-all-out are available
  through the Agent tool.
- **Top tier.** Your own model sets the top tier, exactly as a launch model
  would.

Say once, in one line, that handoffs are on. Then carry on with the work.

If the user invokes `/orc` with a task (`/orc <task>`), treat it as an
on-demand handoff request for that task: suggest the options for it right
away, recommended one first.

"orc off" ends it: say so in one line and stop suggesting handoffs. Nothing
persists; a new session starts plain.

`claude --agent orc:router` at the shell is the same thing from the first turn.
