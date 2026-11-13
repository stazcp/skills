---
type: llm
---

The notes contain: `release-steps.md` and `deploy-checklist.md`, which say the same release steps; `sync-batching.md` (500 records, 2026-09-01), which contradicts the newer `sync-limits.md` (250 records, 2026-10-03); and `oncall.md`, which says "last week" in a note dated 2026-10-20.

PASS if the plan shown to the user proposes all three: merging the two release notes, resolving the batch-size contradiction in favour of 250 (the newer note), and making "last week" an absolute date.
FAIL if any of the three is missing, or the 500-record note is chosen as the survivor.
