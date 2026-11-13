---
type: regex
target: {source: file, path: fieldnotes/release-steps.md}
pattern: '^date: 2026-'
flags: m
---

Plain-folder targets never delete (§4). A file target that is gone fails the
grader; `file_exists` can't say this, as it only checks the run's changed-file
list.
