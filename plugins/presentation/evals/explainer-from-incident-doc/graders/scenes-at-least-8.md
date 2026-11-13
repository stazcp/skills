---
type: regex
pattern: '(?:<section\b(?![^>]*data-closing)[^>]*class="[^"]*\bscene\b[\s\S]*?){8}'
target: { source: file, path: explainer.html }
---
