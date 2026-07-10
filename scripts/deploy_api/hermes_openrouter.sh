#!/usr/bin/env bash
set -euo pipefail

install -d -m 700 "$HOME/.hermes"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  printf 'OPENROUTER_API_KEY=%s\n' "$(gopass show --password api/marco-openrouter-key-1)"
} >"$tmp"

install -m 600 "$tmp" "$HOME/.hermes/.env"
