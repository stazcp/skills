---
type: regex
pattern: '<script\b[^>]*\bsrc\s*=|<link\b[^>]*\bhref\s*=|<(?:img|image|iframe|video|audio|source|object|embed|use)\b[^>]*\b(?:src|href|xlink:href)\s*=\s*["'']?(?:https?:)?//'
flags: i
match: not_contains
target: { source: file, path: explainer.html }
---
