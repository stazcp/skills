#!/usr/bin/env bash
# Builds a local repo with main and a PR branch (pr-212), plus pr/212.md and
# pr/212.diff. Planted bug: the PR claims expired tokens are rejected on every
# entry point, but app/webhooks/receiver.py still calls lookup_token directly,
# so expired tokens keep working on the webhook path.
set -euo pipefail
g() { git -C repo -c user.name=fixture -c user.email=fixture@example.invalid -c commit.gpgsign=false "$@"; }
mkdir -p repo/app/auth repo/app/api repo/app/webhooks repo/docs/decisions repo/tests pr
git -C repo init -q -b main

cat > repo/AGENTS.md <<'EOF'
# Agent instructions
- Design decisions live in docs/decisions/. Read the relevant one before reviewing.
- Python 3.12. Tests: `pytest`.
EOF
cat > repo/docs/decisions/0003-token-checks.md <<'EOF'
# 0003: One token check for every entry point

Status: accepted, 2026-08-14

Every entry point that accepts an API token (the HTTP API, the webhook
receiver, the queue worker) must validate it through the same function in
app/auth/tokens.py, so a rule added there applies everywhere. Entry points
must never call lookup_token directly.
EOF
cat > repo/app/auth/tokens.py <<'EOF'
from dataclasses import dataclass


class InvalidToken(Exception):
    pass


@dataclass
class Token:
    owner: str
    scopes: tuple[str, ...]
    expires_at: float | None  # epoch seconds; None means never expires


_TOKENS: dict[str, Token] = {}


def lookup_token(raw: str) -> Token:
    token = _TOKENS.get(raw)
    if token is None:
        raise InvalidToken("unknown token")
    return token
EOF
cat > repo/app/api/http.py <<'EOF'
from app.auth.tokens import lookup_token


def authenticate(headers: dict[str, str]):
    raw = headers.get("Authorization", "").removeprefix("Bearer ").strip()
    return lookup_token(raw)
EOF
cat > repo/app/webhooks/receiver.py <<'EOF'
from app.auth.tokens import lookup_token


def verify_caller(headers: dict[str, str]):
    """Webhook deliveries carry the caller's API token in X-Api-Token."""
    raw = headers.get("X-Api-Token", "").strip()
    token = lookup_token(raw)
    if "webhooks:write" not in token.scopes:
        raise PermissionError("token lacks webhooks:write")
    return token
EOF
cat > repo/tests/test_tokens.py <<'EOF'
import pytest
from app.auth import tokens
from app.api.http import authenticate


def test_unknown_token_rejected():
    with pytest.raises(tokens.InvalidToken):
        authenticate({"Authorization": "Bearer nope"})
EOF
g add -A && g commit -qm "Token lookup for HTTP API and webhooks"

g checkout -qb pr-212
cat > repo/app/auth/tokens.py <<'EOF'
import time
from dataclasses import dataclass


class InvalidToken(Exception):
    pass


class ExpiredToken(InvalidToken):
    pass


@dataclass
class Token:
    owner: str
    scopes: tuple[str, ...]
    expires_at: float | None  # epoch seconds; None means never expires


_TOKENS: dict[str, Token] = {}


def lookup_token(raw: str) -> Token:
    token = _TOKENS.get(raw)
    if token is None:
        raise InvalidToken("unknown token")
    return token


def check_token(raw: str) -> Token:
    """Look up a token and reject it once it has expired."""
    token = lookup_token(raw)
    if token.expires_at is not None and token.expires_at <= time.time():
        raise ExpiredToken("token expired")
    return token
EOF
cat > repo/app/api/http.py <<'EOF'
from app.auth.tokens import check_token


def authenticate(headers: dict[str, str]):
    raw = headers.get("Authorization", "").removeprefix("Bearer ").strip()
    return check_token(raw)
EOF
cat > repo/tests/test_tokens.py <<'EOF'
import time

import pytest
from app.auth import tokens
from app.api.http import authenticate


def test_unknown_token_rejected():
    with pytest.raises(tokens.InvalidToken):
        authenticate({"Authorization": "Bearer nope"})


def test_expired_token_rejected(monkeypatch):
    monkeypatch.setitem(tokens._TOKENS, "old", tokens.Token("ci", ("read",), time.time() - 1))
    with pytest.raises(tokens.ExpiredToken):
        authenticate({"Authorization": "Bearer old"})
EOF
g add -A && g commit -qm "Reject expired API tokens"

cat > pr/212.md <<'EOF'
# PR #212: Reject expired API tokens everywhere

Author: dkim · base: main · head: pr-212

Tokens have had an `expires_at` since August but nothing enforced it. This
adds `check_token`, which rejects a token once `expires_at` has passed, and
switches token validation over to it, so **expired tokens are rejected on
every entry point**, per decision 0003.

Closes #198.

Testing: new `test_expired_token_rejected`.
EOF
g diff main pr-212 > pr/212.diff
