---
name: presentation
description: >-
  Turn a dense source (a doc, an HTML page, a markdown file, a tracker issue, or
  a topic) into a short animated step-through HTML explainer that someone
  understands in about 3 minutes, built only from that source, with 8 to 12
  scenes, one animated diagram each, and honest Confirmed / Likely / Not known
  chips. Writes one self-contained file and reports the path. It never
  publishes, uploads or shares. Use when the user says /presentation, "make a
  presentation", "make an animated explainer", "simplify this into slides",
  "turn this into a walkthrough", or "explain this in 3 minutes".
argument-hint: "<source> [--audience private|internal|external] [--out <path>]"
---

# Presentation

## What this is

A dense source in, a three-minute explainer out. The reader clicks Next about
ten times, sees one animated diagram per step, reads a sentence or two, and
comes away with the shape of the thing, including what nobody knows yet. It
gives them the shape and points to the source for detail. It doesn't replace
the source.

The output is one HTML file on disk. The skill's job ends there.

## The one rule

**Derive only from the named source, and never let it leave.** Every scene,
label, chip and arrow traces back to something the source says. Nothing is
added from memory, from a sibling file, or from what usually happens in
systems like this. When the source is unclear, the point is left out or marked
Not known. The skill writes a file and reports its path. It never uploads,
posts, publishes or shares anything, and never offers a command that would.

A clear explainer that adds one invented link is worse than none, because the
reader can't see which arrow is invented and trusts all of them.

## The context: load this first

Organisation-specific defaults live in your context folder, never in this
file. The folder is `$SKILLZ_CONTEXT`, or `~/.config/skillz` when that is
unset; point it (or symlink it) wherever you keep private settings.

    <context>/presentation.md    default output location, how to save there,
                                 what may leave it, audience default

If the file or the folder is missing, there are no defaults: write next to the
source when the source is a local file, otherwise ask for `--out`, and say in
the report that the context had nothing to say. Where the context and this
file disagree on *where* or *how to save*, the context wins. On *what the
explainer may contain*, this file wins.

Two files sit next to this one, in the skill's own directory:

- `skeleton.html` is the page machinery: tokens, dark mode, nav, the
  animation vocabulary, reduced motion, the chip legend. Start from a copy of it.
- `check.py` runs the checks in step 6. It needs only the standard library,
  and it uses headless Chrome when it can find it.

## 1. Arguments

- `<source>` is a file path, a URL to a page the host can read, an issue
  reference, or a topic. For a topic, ask which document is the source.
  "Everything you know" is not a source.
- `--audience` defaults to whatever the source's own banner says. If the source
  has no banner, it defaults to what the context sets, and failing that to
  `private`.
  - `private`: the user alone.
  - `internal`: colleagues inside the organisation.
  - `external`: anyone.
- `--out` overrides the location. Otherwise the context decides, as above.

## 2. Source discipline (gate)

Read the whole source before planning a scene.

- **Audience must not widen.** If the source carries a banner narrower than
  `--audience` (it says private, the request says internal), stop.
- **Wider than private means already cleaned.** For `internal` or `external`,
  scan the source itself before using it: secrets, key or token ids (even
  partial), customer names or other PII, DM or private-chat excerpts, and
  personal remarks about people. Any hit means stop. Say what kinds of thing
  you found, not the values, and offer to make a cleaned edition of the source
  first. Build only from the cleaned edition, after the user has seen it.
- **One source.** Never fill a gap from a sibling file, an older draft or a
  less-clean edition of the same document, even one in the same folder. If the
  source links out, follow a link only when the user says to, and then that
  page is a source too, held to the same gate.
- **Extracts stay private.** Any notes, fact sheets or renders made from a
  sensitive source go in the session's scratchpad (or the host's temp dir when
  it has none), never beside the output or in a repo.

## 3. Fact sheet

Before designing anything, write a short fact sheet to the scratchpad. Each
line is one claim, its grade, and where in the source it is (a heading or a
quote of a few words).

If the source grades its claims, map the grades onto exactly four chips. If a
source scheme is E/R/I/U or similar, map it by meaning, and say how you mapped
it in the report.

| Chip | Means | Typical source grades |
|---|---|---|
| Confirmed | established by evidence in the source | verified, evidenced, E |
| Likely | the source's best reading, not proven | inferred, probable, I |
| Not known | the source says it is open, or doesn't say | unknown, open, U |
| Reported | someone said so, unverified (shown muted) | reported, claimed, R |

If the source doesn't grade, chips are optional. Use Not known only where the
source itself says something is open. An ungraded statement is not
automatically Confirmed: if you would need to guess its grade, leave the chip
off.

Each scene is then picked from this sheet. Nothing reaches a scene that isn't
on it.

## 4. Shape

About **8–12 scenes plus a closing slide**.

- **Open with the system before**: what existed and how it normally worked,
  so the later scenes have something to change.
- **Then the sequence**: one idea per scene, in the order a newcomer needs
  them. That is usually cause before effect, and not always the source's own
  order.
- **Close with "what we don't know" and "what's still open"** when the source
  has any. These are scenes, not footnotes.
- **The closing slide** links to the full source and says that is where the
  evidence lives.

Each scene has:

- a kicker (step number and a one-word stage) and a plain headline that
  states the point;
- **one** animated inline-SVG diagram, the scene's real content: a token
  moving along an edge, a box lighting up, a lock breaking or closing, an edge
  drawing in. The motion is the point of the scene, not decoration;
- **at most about 40 words** of plain-language prose in `p.say`. Use no jargon
  the source didn't force, and no acronym without its expansion the first time;
- chips for the claims the scene shows, when the source grades them.

Reuse one visual layout across scenes, with the same boxes in the same places,
so the reader tracks change rather than re-reading a new picture every time.

## 5. Honesty in the visuals

- **Unestablished links are `.edge.unknown`**: dashed, muted, labelled `?`.
  A `.token` never travels along one, and nothing lights up because of one.
  `check.py` fails the build if a token's path matches an unknown edge.
- **Chip legend in the footer** whenever chips appear; delete it when none do.
- **No new facts.** A label, number, time or name that isn't on the fact sheet
  doesn't go in a diagram either. Simplifying means removing things, never
  rounding a claim up. "Probably caused" doesn't become an arrow labelled
  "caused".
- **Reported is muted**: grey and outlined, never the accent colour.
- **The banner carries through**: the source's audience label and its "as of"
  date, verbatim, in the page banner. If the source has no date, use the date
  you read it and say "read on" instead of "as of".

## 6. Format

One self-contained `.html` file.

- Inline CSS, inline SVG and a little vanilla JS. No external scripts,
  stylesheets, fonts, images, libraries or CDNs, and no network calls. A link
  to the source on the closing slide is the one exception, and it is a plain
  `<a href>`.
- Built from `skeleton.html`: keep its tokens, nav (Next/Back buttons, ←/→
  keys, progress dots, `#n` deep links), `?theme=` and `?motion=` hooks, and
  the error hook in `<head>`. Replace every `{{PLACEHOLDER}}` and the example
  scenes.
- Respect `prefers-reduced-motion`: every animated element shows its end
  state with no movement. The skeleton's two reduced-motion blocks do this for
  its vocabulary. A new animation class needs a line in both.
- Works in dark mode (colours only from the tokens) and in a laptop-height
  window (about 680px of viewport) without scrolling. A phone width may
  scroll.
- Inline SVG must be valid XML: `&#160;` rather than `&nbsp;`, every element
  closed, attributes quoted. Keep viewBoxes about 640 units wide and labels
  16 units or more, so they still read at phone width. On narrow screens,
  prefer fewer boxes to smaller text.

## 7. Delegation

When the host supports sub-agents, handing the build to one is fine. Give it
the source path, the fact sheet, the audience, the output path, the skeleton
path and sections 4–6 of this file. Give it nothing else from the session. It
returns the file, and then **run the checks yourself**: its report that the
checks pass is not evidence. Compare every scene against the fact sheet
before handing back. Delegation moves the typing, not the responsibility for
honesty.

## 8. Checks before handing back

```bash
python3 -I <skill dir>/check.py <out.html> --audience <a> --render <scratchpad>/renders
```

It checks:

- **Structure**: HTML tags balance, and every `<svg>` parses as XML.
- **Self-containment**: no external assets.
- **Shape**: scene count, words per scene, one diagram per scene, and a
  closing slide that links out.
- **Motion and theme**: reduced-motion and dark-mode rules are present.
- **Honesty**: no token moves along an unknown edge.
- **Scan**: secrets and PII patterns. The hits are printed redacted.
- **Render** (`--render`): headless Chrome renders every scene in light,
  dark and narrow (390px) at end state into PNGs, catches JS errors, and
  checks that `#1` and `#last` each show exactly one scene. If the host
  sandbox blocks Chrome, rerun that one command outside the sandbox. If
  there's no Chrome, say the render was skipped. Don't claim it passed.

Then **look at every PNG**. Overlapping labels, text running off a box, a
diagram clipped at laptop height, a chip row wrapping over the prose: fix,
re-run, look again. Overlap is a judgement, and the script can't make it.

The scan covers GitHub tokens (`gh[pousr]_`, `github_pat_`), AWS key ids
(`AKIA`/`ASIA`), PEM blocks, Slack tokens and webhooks, `sk_live_`, `whsec_`,
JWTs (`eyJ…`), 32+ character hex or base64 runs, email addresses, local paths
(`/Users/`, `/home/`, `/tmp/`, `/private/…`) and private/DM markers. For a
non-private audience, every hit must be cleared or explained before the file is
handed back. For private, report them anyway.

## 9. Report back

Report in the terminal. No file, no post.

- **Path** of the explainer, absolute.
- **Scenes**: one line each, the headline.
- **Checks**: errors and warnings from `check.py`, and whether the render ran.
- **Scan**: every hit (redacted, as printed) and what you did about it, or
  "none".
- **Left out**: what the source says that the explainer doesn't, to keep it
  simple. This tells the user what the three minutes cost.
- **Grade mapping**, if the source's scheme was mapped onto the chips.
- **Temporary files** you created (fact sheet, renders, any extracts), as
  absolute paths, so the user can delete them. Don't delete them yourself
  unless asked.
- Anything the context file required on save (a commit, say), with its result.

Never end with an offer to publish, upload or share. If the user asks for that
afterwards, it's a separate request, outside this skill.
