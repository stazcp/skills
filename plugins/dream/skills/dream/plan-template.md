# Dream plan and journal shapes

The engine (`SKILL.md`) writes `plan.md` into the backup directory before
asking, and `journal.md` (or the vault's journal note) after applying. Keep
these shapes so a plan from one run reads like a plan from another.

## plan.md

    # Dream plan: <target label>

    Target: <path>            Read: <N> files, <M> lines
    Backup: <backup dir>/before/   Taken: <YYYY-MM-DD HH:MM>
    Verified: <k> claims checked, <u> could not be checked (marked unverified)

    ## Changes

    | # | Kind | Files | Change | Reason |
    |---|---|---|---|---|
    | 1 | merge | a.md + b.md → a.md | b's two facts into a; b retired (delete / archive / mark) | same topic, same claim, b dated 2026-03-02, a 2026-04-10 |
    | 2 | resolve | c.md vs d.md | d wins (2026-05-01 > 2026-02-11); c marked superseded → [[d]] | contradict on <what> |
    | 3 | retire | e.md | archive to Archive/ (or: delete; or: mark superseded) | PR 1234 merged 2026-04-20, checked today |
    | 4 | pattern | f.md, g.md, h.md → new i.md | one root cause note; f, g, h link to it | three notes record the same mistake |
    | 5 | absolutize | j.md | "last week" → 2026-03-16 (note dated 2026-03-23) | |
    | 6 | link | k.md ↔ l.md | add [[l]] / [[k]] | same decision, no link |
    | 7 | tighten | m.md | 41 → 19 lines, facts unchanged | |
    | 8 | rename | n.md → <new>.md | basename clash / convention | spec Conventions |
    | 9 | index | MEMORY.md (or <Index note>) | group under: <headings> | 34 entries |

    ## Left alone
    - <file>: <why nothing changes>

    ## Could not verify
    - <file>: <claim> — <what was tried>

Kinds: merge, resolve, retire, pattern, absolutize, link, tighten, rename,
index. A retire line always says how (delete / archive / mark) and what was
checked. Every delete is a retire line; there is no other way to delete.

## journal.md / `YYYY-MM-DD Dream journal.md`

    # Dream journal: <target label>, <YYYY-MM-DD>

    Applied: <n> of <m> planned changes (<plan.md path>)
    Backup: <backup dir>/before/
    Commit: <hash> · <pushed | push blocked: <reason> | no remote | no git>

    ## What changed
    - <one line per applied change, past tense, with the files>

    ## Left alone
    - <what was deliberately not touched, and why>

    ## Could not verify
    - <claim and file, now marked unverified>

    ## Open questions
    - <one line each: what only the user can settle>

No note contents are quoted in a journal for a vault marked private; name
the files and the kind of change.
