#!/usr/bin/env bash
# Run the `claude plugin eval` suite of every plugin changed against a base ref.
#
#   scripts/eval-changed.sh [--all] [--base <ref>] [--max-cost-usd <usd>] [--dry-run]
#
# Changed = `git diff --name-only <base>...HEAD` plus uncommitted and untracked
# files, under plugins/<name>/. Cheap mode (--runs 1 --ablation none), a cost cap
# per plugin, results in a temp dir. A failing case is rerun once on its own
# before it counts (LLM-judge flakiness).
#
# On an overall pass with a clean tree it writes the marker
#   $(git rev-parse --git-common-dir)/evals-passed/$(git rev-parse HEAD)
# which a Claude Code hook checks before `gh pr create`. Keep that path stable.
#
# Exit: 0 pass, 1 an eval failed, 2 usage/setup error, 3 a real brain vault changed.
set -euo pipefail

BASE="origin/main"
BASE_SET=0
ALL=0
DRY=0
CAP="3"   # USD per plugin (suite + reruns); cases cost ~$0.12-0.37 per run

usage() { sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; }

while [ $# -gt 0 ]; do
  case "$1" in
    --all) ALL=1 ;;
    --base) [ $# -ge 2 ] || { echo "--base needs a ref" >&2; exit 2; }; BASE="$2"; BASE_SET=1; shift ;;
    --max-cost-usd) [ $# -ge 2 ] || { echo "--max-cost-usd needs a value" >&2; exit 2; }; CAP="$2"; shift ;;
    --dry-run) DRY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

ROOT="$(git rev-parse --show-toplevel)"
cd "$ROOT"
START_HEAD="$(git rev-parse HEAD)"

need() { command -v "$1" >/dev/null 2>&1 || { echo "error: $1 not found on PATH" >&2; exit 2; }; }
need jq
[ "$DRY" = 1 ] || need claude

# ---------- which plugins ----------
ALL_PLUGINS=()
for d in plugins/*/; do
  [ -d "$d" ] && ALL_PLUGINS+=("$(basename "$d")")
done

if [ "$ALL" = 1 ]; then
  PLUGINS=("${ALL_PLUGINS[@]}")
else
  if [ "$BASE_SET" = 0 ]; then
    git fetch --quiet origin main 2>/dev/null || echo "warning: git fetch origin main failed; using local $BASE" >&2
  fi
  git rev-parse --verify --quiet "$BASE^{commit}" >/dev/null || { echo "error: base ref '$BASE' not found" >&2; exit 2; }
  CHANGED_FILES="$( {
    git diff --name-only "$BASE...HEAD"
    git diff --name-only HEAD              # staged + unstaged
    git ls-files --others --exclude-standard
  } | sort -u )"
  PLUGINS=()
  for p in "${ALL_PLUGINS[@]}"; do
    if printf '%s\n' "$CHANGED_FILES" | grep -q "^plugins/$p/" ; then PLUGINS+=("$p"); fi
  done
fi

# ---------- per-plugin tool grants ----------
# Path-scoped Write grants are denied inside eval runs, so grants are bare.
# brain's cases list Write, Edit and Bash; Bash runs under the eval OS sandbox.
grants_for() {
  case "$1" in
    standup)      GRANTS=(Bash) ;;  # reads notes with one chained command; prefix grants deny it
    review-pr)    GRANTS=("Bash(git *)") ;;
    presentation) GRANTS=(Write) ;;
    brain)        GRANTS=(Write Edit Bash) ;;
    *)            GRANTS=() ;;
  esac
}
writes_files() { [ "$1" = brain ] || [ "$1" = presentation ]; }

# ---------- real brain vault guard (local only) ----------
TMPBASE="${TMPDIR:-/tmp}"; TMPBASE="${TMPBASE%/}"
BRAIN_DIR="${BRAIN_HOME:-$HOME/.config/brain}"
SNAP_DIR=""
vault_paths() {
  # Brain home itself plus every spec's **Path** (see plugins/brain/skills/brain/SKILL.md §1).
  [ -d "$BRAIN_DIR" ] || return 0
  echo "$BRAIN_DIR"
  for spec in "$BRAIN_DIR"/*.md "$BRAIN_DIR"/*/brain.md; do
    [ -f "$spec" ] || continue
    case "$(basename "$spec")" in TEMPLATE*|vault-template.md) continue ;; esac
    path="$(sed -n 's/.*\*\*Path\*\*:[[:space:]]*`\{0,1\}\([^`]*\)`\{0,1\}.*/\1/p' "$spec" | head -1)"
    [ -n "$path" ] || continue
    case "$path" in "~"*) path="$HOME${path#\~}" ;; esac
    path="${path%/}"
    [ -d "$path" ] && echo "$path"
  done | sort -u
}
snapshot_vaults() {  # $1 = before|after; one file per vault, so a change names its vault
  local i=0 v f
  while IFS= read -r v; do
    [ -n "$v" ] || continue
    i=$((i + 1)); f="$SNAP_DIR/$1.$i"
    echo "$v" > "$f"
    if git -C "$v" rev-parse --git-dir >/dev/null 2>&1; then
      { git -C "$v" rev-parse HEAD 2>/dev/null || echo "no-head"; git -C "$v" status --porcelain; } >> "$f"
    else
      # Not a git repo: file count, plus (after) any file newer than the pre-run stamp.
      find "$v" -type f | wc -l | tr -d ' ' >> "$f"
      if [ "$1" = after ]; then find "$v" -type f -newer "$SNAP_DIR/stamp" >> "$f"; fi
    fi
  done < <(vault_paths)
  echo "$i" > "$SNAP_DIR/$1.count"
}
vault_guard_start() {
  [ -z "${CI:-}" ] || return 0
  local paths; paths="$(vault_paths)"
  if [ -z "$paths" ]; then
    echo "  vault guard: no brain vault config at $BRAIN_DIR; nothing to protect, continuing"
    return 0
  fi
  if [ "$DRY" = 1 ]; then
    echo "  vault guard: would snapshot $(printf '%s\n' "$paths" | tr '\n' ' ')before and after"
    return 0
  fi
  SNAP_DIR="$(mktemp -d "$TMPBASE/eval-vaults.XXXXXX")"
  touch "$SNAP_DIR/stamp"
  sleep 1   # so -newer cannot match a file written in the same second as the stamp
  snapshot_vaults before
}
vault_guard_check() {  # $1 = plugin
  [ -n "$SNAP_DIR" ] || return 0
  snapshot_vaults after
  local changed=() i n
  n="$(cat "$SNAP_DIR/before.count")"
  [ "$n" = "$(cat "$SNAP_DIR/after.count")" ] || changed+=("vault list under $BRAIN_DIR")
  i=1
  while [ "$i" -le "$n" ]; do
    cmp -s "$SNAP_DIR/before.$i" "$SNAP_DIR/after.$i" 2>/dev/null || changed+=("$(head -1 "$SNAP_DIR/before.$i")")
    i=$((i + 1))
  done
  if [ ${#changed[@]} -gt 0 ]; then
    {
      echo ""
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "!! A REAL BRAIN VAULT CHANGED DURING THE $1 EVALS. STOPPING."
      for v in "${changed[@]}"; do echo "!!   changed: $v"; done
      echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      echo "Before/after snapshots kept in $SNAP_DIR"
    } >&2
    exit 3
  fi
  rm -rf "$SNAP_DIR"; SNAP_DIR=""
}

# ---------- running ----------
TMP_ROOT=""
if [ "$DRY" = 0 ] && [ ${#PLUGINS[@]} -gt 0 ]; then TMP_ROOT="$(mktemp -d "$TMPBASE/eval-changed.XXXXXX")"; fi

fadd() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.4f", a+b}'; }
fsub() { awk -v a="$1" -v b="$2" 'BEGIN{printf "%.4f", a-b}'; }
fpos() { awk -v a="$1" 'BEGIN{exit !(a>0)}'; }

# run_eval <plugin> <outdir> <cap> [--case name]; sets RC, writes <outdir>/result.json and log
run_eval() {
  local p="$1" out="$2" cap="$3"; shift 3
  grants_for "$p"
  local cmd=(claude plugin eval "plugins/$p" --scaffold --runs 1 --ablation none
             --trust-plugin --no-publish --max-cost-usd "$cap"
             --output-dir "$out" --report "$out/report.html" --json "$out/result.json" "$@")
  if [ ${#GRANTS[@]} -gt 0 ]; then cmd+=(--allow-tools "${GRANTS[@]}"); fi
  if [ "$DRY" = 1 ]; then
    printf '  would run:'; printf ' %q' "${cmd[@]}"; printf '\n'
    RC=0; return 0
  fi
  mkdir -p "$out"
  RC=0
  "${cmd[@]}" > "$out/stdout.log" 2> "$out/stderr.log" || RC=$?
}
json_cost() { [ -f "$1" ] && jq -r '.costUsd // 0' "$1" 2>/dev/null || echo 0; }
# Failed = with-arm score below the default --threshold of 1.0.
json_failed() { jq -r '.cases[] | select((.aggregates.score // 0) < 1) | .name' "$1" 2>/dev/null; }

SUMMARY=()
OVERALL=0

if [ ${#PLUGINS[@]} -eq 0 ]; then
  echo "No plugin changed against $BASE; nothing to eval."
fi

for p in "${PLUGINS[@]+"${PLUGINS[@]}"}"; do
  if [ ! -d "plugins/$p/evals" ]; then
    SUMMARY+=("$p: skip (no evals/ dir)"); continue
  fi
  echo "==> $p"
  guarded=0
  if writes_files "$p" && [ -z "${CI:-}" ]; then vault_guard_start; guarded=1; fi

  dir="${TMP_ROOT:-/tmp/eval-changed.DRY}/$p"
  run_eval "$p" "$dir/suite" "$CAP"
  if [ "$DRY" = 1 ]; then
    echo "  then: rerun each failed case once with --case <name>"
    SUMMARY+=("$p: dry-run"); continue
  fi
  cost="$(json_cost "$dir/suite/result.json")"
  status=pass; failing=()

  if [ "$RC" -ne 0 ]; then
    if [ "$RC" -eq 2 ]; then
      status=fail; failing=("cost-ceiling-or-auth")
    elif [ ! -s "$dir/suite/result.json" ] || ! jq -e '.cases' "$dir/suite/result.json" >/dev/null 2>&1; then
      status=fail; failing=("load-failure")
    else
      first_failed="$(json_failed "$dir/suite/result.json")"
      if [ -z "$first_failed" ]; then
        status=fail; failing=("exit-1-no-failing-case")
      else
        while IFS= read -r c; do
          [ -n "$c" ] || continue
          left="$(fsub "$CAP" "$cost")"
          if ! fpos "$left"; then failing+=("$c(no budget to rerun)"); continue; fi
          echo "  rerunning $c (flake check)"
          run_eval "$p" "$dir/rerun-$c" "$left" --case "$c"
          cost="$(fadd "$cost" "$(json_cost "$dir/rerun-$c/result.json")")"
          if [ "$RC" -ne 0 ]; then failing+=("$c"); fi
        done <<< "$first_failed"
        [ ${#failing[@]} -eq 0 ] || status=fail
      fi
    fi
    if [ "$status" = fail ]; then
      echo "  stderr (last lines) from $dir/suite/stderr.log:" >&2
      tail -n 15 "$dir/suite/stderr.log" >&2 || true
    fi
  fi

  [ "$guarded" = 0 ] || vault_guard_check "$p"
  line="$p: $status"
  [ ${#failing[@]} -eq 0 ] || line="$line [$(IFS=,; echo "${failing[*]}")]"
  line="$line \$$(printf '%.2f' "$cost")"
  SUMMARY+=("$line")
  [ "$status" = pass ] || OVERALL=1
done

echo ""
echo "Summary:"
for s in "${SUMMARY[@]+"${SUMMARY[@]}"}"; do echo "  $s"; done
[ -z "$TMP_ROOT" ] || echo "Results: $TMP_ROOT"

if [ "$OVERALL" -ne 0 ]; then
  echo "FAIL: evals did not pass; no marker written."
  exit 1
fi

MARKER_DIR="$(git rev-parse --git-common-dir)/evals-passed"
MARKER="$MARKER_DIR/$(git rev-parse HEAD)"
if [ "$(git rev-parse HEAD)" != "$START_HEAD" ]; then
  echo "PASS, but HEAD moved during the run (was $START_HEAD): no marker written. Rerun."
elif [ -n "$(git status --porcelain)" ]; then
  echo "PASS, but the working tree is dirty: no marker written (it would vouch for HEAD, which is not what ran). Commit, then rerun."
elif [ "$DRY" = 1 ]; then
  echo "dry-run: would write marker $MARKER"
else
  mkdir -p "$MARKER_DIR"
  date -u +%Y-%m-%dT%H:%M:%SZ > "$MARKER"
  echo "PASS: marker written $MARKER"
fi
