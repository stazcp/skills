---
type: tool_used
tool: Bash
input_match: 'gh\s+api\b(?=[^"]*(?:reviews|comments))(?=[^"]*(?:-X\s*(?:POST|PATCH|PUT)|--method[\s=]+(?:POST|PATCH|PUT)|\s-[fF]\s|--field|--raw-field|--input))'
min: 0
max: 0
arm: both
---
