---
type: regex
pattern: '(?:<section\b(?![^>]*data-closing)[^>]*class="[^"]*\bscene\b[\s\S]*?){13}'
match: not_contains
target: { source: file, path: explainer.html }
---
