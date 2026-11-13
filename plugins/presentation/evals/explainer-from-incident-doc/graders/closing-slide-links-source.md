---
type: regex
pattern: '<section\b[^>]*data-closing[\s\S]*?<a\b[^>]*href=[\s\S]*?</section>'
target: { source: file, path: explainer.html }
---
