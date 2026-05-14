#!/usr/bin/env bash
set -euo pipefail

GPG_BACKUP_DIR="$HOME/.dotfiles/gpg"

PUBLIC_KEY="$GPG_BACKUP_DIR/public.asc"
PRIVATE_KEY="$GPG_BACKUP_DIR/private.asc.gpg"
OWNERTRUST="$GPG_BACKUP_DIR/ownertrust.txt"

if ! command -v gpg >/dev/null 2>&1; then
  echo "Error: gpg is not installed." >&2
  exit 1
fi

if [ ! -d "$GPG_BACKUP_DIR" ]; then
  echo "Error: GPG backup directory not found: $GPG_BACKUP_DIR" >&2
  exit 1
fi

if [ ! -f "$PUBLIC_KEY" ]; then
  echo "Error: public key not found: $PUBLIC_KEY" >&2
  exit 1
fi

if [ ! -f "$PRIVATE_KEY" ]; then
  echo "Error: encrypted private key not found: $PRIVATE_KEY" >&2
  exit 1
fi

export GPG_TTY="${GPG_TTY:-$(tty)}"
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true

mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

echo "Importing public key..."
gpg --import "$PUBLIC_KEY"

echo "Importing encrypted private key..."
gpg --decrypt "$PRIVATE_KEY" | gpg --import

if [ -f "$OWNERTRUST" ]; then
  echo "Importing owner trust..."
  gpg --import-ownertrust "$OWNERTRUST"
fi

chmod 700 "$HOME/.gnupg"
find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
find "$HOME/.gnupg" -type d -exec chmod 700 {} \;

echo "Done."
