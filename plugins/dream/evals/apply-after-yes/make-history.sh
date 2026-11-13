#!/usr/bin/env bash
# Builds history.jsonl: the replayed session this case resumes (context.history_file,
# passed to `claude --resume`, so it is a Claude Code session transcript). It holds
# the user's `/dream ./fieldnotes`, the skill body that slash command expands to,
# and the assistant's plan ending in the approval question. The next turn
# (prompt.md) is the user's yes.
#
#   make-history.sh          rewrite history.jsonl from the current SKILL.md
#   make-history.sh --check  exit 1 if history.jsonl's skill body is stale
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL="$HERE/../../skills/dream/SKILL.md"
OUT="$HERE/history.jsonl"

# SKILL.md without its frontmatter, as a slash command expands it.
body() { awk 'NR==1 && /^---$/ {fm=1; next} fm && /^---$/ {fm=0; next} !fm' "$SKILL"; }

if [ "${1:-}" = "--check" ]; then
  want="$(body)"
  have="$(jq -r 'select(.isMeta == true) | .message.content[0].text' "$OUT" | sed '$d' | sed '$d')"
  [ "$want" = "$have" ] && exit 0
  echo "history.jsonl is stale against SKILL.md; run $HERE/make-history.sh" >&2
  exit 1
fi

SID="5d1f0c3e-7a2b-4c9d-8e6f-0a1b2c3d4e5f"
TS="2026-11-13T09:00:00.000Z"
PLAN="$(cat <<'MD'
Read 5 files in `fieldnotes/`. Nothing names a file, PR or flag to verify.

Backup: `~/.local/state/dream/fieldnotes/20261113-090000/before/`
Plan: `~/.local/state/dream/fieldnotes/20261113-090000/plan.md`

**1 merge, 1 resolve, 2 retires (mark, no deletes), 1 absolutize**

Retires:
- **2.** `deploy-checklist.md`: mark `status: superseded` in its frontmatter and link [Release steps](release-steps.md). Kept, not deleted.
- **4.** `sync-batching.md`: mark `status: superseded` in its frontmatter and link [Sync limits](sync-limits.md). Kept, not deleted.

The rest:
1. merge: `release-steps.md` + `deploy-checklist.md` → `release-steps.md` (same three steps; release-steps is the earlier note, 2026-08-14). The staging token in deploy-checklist is a secret: dropped, not carried into the merge.
3. resolve: `sync-batching.md` (500 records, 2026-09-01) vs `sync-limits.md` (250 records, 2026-10-03): the newer wins; `sync-limits.md` says it supersedes the 500-record cap as of 2026-10-03.
5. absolutize: `oncall.md` "Last week" → "The week of 2026-10-13" (note dated 2026-10-20).

How should I go ahead: **apply all**, **apply selected** (name the numbers), or **plan only**? And do you want a dream journal written to the backup directory?
MD
)"

{
  jq -nc --arg sid "$SID" --arg ts "$TS" '{
    parentUuid: null, isSidechain: false, type: "user", userType: "external",
    message: {role: "user", content: "<command-message>dream:dream</command-message>\n<command-name>/dream:dream</command-name>\n<command-args>./fieldnotes</command-args>"},
    uuid: "00000000-0000-4000-8000-000000000001", timestamp: $ts, sessionId: $sid}'
  jq -nc --arg sid "$SID" --arg ts "$TS" --arg text "$(body)

ARGUMENTS: ./fieldnotes" '{
    parentUuid: "00000000-0000-4000-8000-000000000001", isSidechain: false, type: "user", userType: "external",
    isMeta: true,
    message: {role: "user", content: [{type: "text", text: $text}]},
    uuid: "00000000-0000-4000-8000-000000000002", timestamp: $ts, sessionId: $sid}'
  jq -nc --arg sid "$SID" --arg ts "$TS" --arg text "$PLAN" '{
    parentUuid: "00000000-0000-4000-8000-000000000002", isSidechain: false, type: "assistant", userType: "external",
    message: {id: "msg_dream_apply_eval_0001", type: "message", role: "assistant", model: "<synthetic>",
              content: [{type: "text", text: $text}], stop_reason: "end_turn", stop_sequence: null,
              usage: {input_tokens: 0, output_tokens: 0}},
    uuid: "00000000-0000-4000-8000-000000000003", timestamp: $ts, sessionId: $sid}'
} > "$OUT"
echo "wrote $OUT"
