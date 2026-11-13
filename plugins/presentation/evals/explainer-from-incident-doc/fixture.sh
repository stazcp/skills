#!/usr/bin/env bash
# Writes the source doc: an internal incident review with graded claims,
# an audience banner and an as-of date. No secrets or PII, so the internal
# audience scan has nothing to stop on.
set -euo pipefail
cat > incident-review.md <<'EOF'
> Audience: internal · As of 2026-10-02

# Incident review: checkout timeouts, 2026-09-28

Grades: [E] established, [R] reasonable inference, [I] reported by someone, [U] unknown.

## Summary

For 47 minutes on 2026-09-28, about 18% of checkout requests timed out. [E]
No orders were lost; customers who retried succeeded. [E]

## The system

Checkout calls three services in order: Cart, Pricing and Payments. [E]
Pricing reads discount rules from a shared Redis cache, and on a cache miss
it reads them from the Rules database. [E]
Each checkout request has a 5-second budget end to end. [E]

## Timeline

- 14:02 A deploy of Pricing v4.12 started. [E]
- 14:05 The Redis cache was flushed as part of the deploy. [E]
- 14:06 Checkout p99 latency rose from 0.8 s to 6.1 s. [E]
- 14:20 On-call paged; the dashboards showed Rules database CPU at 100%. [E]
- 14:41 Pricing v4.12 rolled back. [E]
- 14:49 Latency back to normal. [E]

## What happened

After the flush, every Pricing instance missed the cache at once and went to
the Rules database (a cache stampede). [R]
The Rules database saturated, Pricing calls took longer than the 5-second
budget, and checkout timed out. [E]
v4.12 also changed how discount rules are keyed, which may have made the
misses last longer than a plain flush would. [R]
The support team reported that mobile users were hit harder than web users. [I]

## What we don't know

Whether the key change in v4.12 alone, without the flush, would have caused
the incident. [U]
Why the cache did not refill within the first few minutes. [U]

## Actions

1. Stop flushing the cache on deploy. Owner: Pricing team. Done. [E]
2. Add request coalescing so only one instance refills a missing key. Owner: Pricing team. Due 2026-10-30.
3. Alert on Rules database CPU above 80% for 2 minutes. Owner: SRE. Due 2026-10-15.
EOF
