#!/usr/bin/env bash
# Builds a throwaway brain home + vault for this run. Never touches real vaults:
# refuses to run unless HOME is the eval's temporary home.
set -euo pipefail
case "$HOME" in /Users/*|/home/*|/root|"") echo "refusing: HOME=$HOME is not a temp home" >&2; exit 1;; esac
if [ -e "$HOME/.config/brain" ]; then echo "refusing: $HOME/.config/brain already exists" >&2; exit 1; fi
VAULT="$PWD/vault"
mkdir -p "$VAULT/Decisions" "$VAULT/Inbox" "$VAULT/Projects" "$HOME/.config/brain"
cat > "$VAULT/Home.md" <<'MD'
# Home

Index of this vault.

- [[Offline sync design]]
MD
cat > "$VAULT/Projects/Offline sync design.md" <<'MD'
---
date: 2026-10-03
tags: [project]
---
# Offline sync design

## 2026-10-03

- Conflict resolution is last-writer-wins per field, decided with the mobile lead.
- Sync batches cap at 250 records because the gateway rejects bodies over 1 MB.
- Codename for the rollout is BLUE HERON.
MD
GITLINE="none"
cat > "$HOME/.config/brain/eval.md" <<MD
# Vault spec

## Vault

- **Name**: eval
- **Path**: \`$VAULT\`
- **Private**: no
- **Git**: $GITLINE
- **Sandbox**: writes inside the workspace are allowed
- **Backup**: none

## What belongs

Engineering decisions, findings and project notes.

## Never here

Nothing is excluded.

## Conventions

- **Filename**: a plain title, e.g. \`Offline sync design.md\`
- **Frontmatter**: \`date\` and \`tags\`
- **Appending**: dated \`## YYYY-MM-DD\` section

## Filing

- Decisions go in \`Decisions/\`, project notes in \`Projects/\`.
- **Index**: \`Home.md\`
- **Inbox**: \`Inbox/\`
- **Archive**: none

## Daily log

Off

## Recall

Read \`Home.md\` first.
MD
echo eval > "$HOME/.config/brain/active"
