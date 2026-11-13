#!/usr/bin/env bash
# Seeds a throwaway skillz context in the run's temp HOME. Refuses a real HOME.
set -euo pipefail
case "$HOME" in /Users/*|/home/*|/root|"") echo "refusing: HOME=$HOME is not a temp home" >&2; exit 1;; esac
if [ -e "$HOME/.config/skillz" ]; then echo "refusing: $HOME/.config/skillz already exists" >&2; exit 1; fi
mkdir -p "$HOME/.config/skillz"
cat > "$HOME/.config/skillz/prefs.md" <<'MD'
# Prefs

- github_user: octocat
- gh_orgs: eval-fixture-org
- Main focus: the PELICAN billing migration
MD
cat > "$HOME/.config/skillz/notes.md" <<'MD'
# Notes

- Spent yesterday pairing on the PELICAN invoice backfill dry run (not in GitHub).
- Blocked: waiting on the finance lead to sign off the backfill cutover date.
MD
