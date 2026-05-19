#!/usr/bin/env bash
set -euo pipefail

install -d -m 700 "$HOME/.hermes"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

{
  printf 'OPENROUTER_API_KEY='
  gopass show api/marco-openrouter-key-1 | head -n1
  printf '\n'
} >"$tmp"

install -m 600 "$tmp" "$HOME/.hermes/.env"
