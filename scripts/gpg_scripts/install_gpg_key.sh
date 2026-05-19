#!/usr/bin/env bash
set -euo pipefail

GPG_BACKUP_DIR="${GPG_BACKUP_DIR:-$HOME/.dotfiles/gpg}"
BACKUP_FILE="${GPG_BACKUP_FILE:-$GPG_BACKUP_DIR/gpg-key-backup.tar.gz.gpg}"

if ! command -v gpg >/dev/null 2>&1; then
  echo "Error: gpg is not installed." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "Error: tar is not installed." >&2
  exit 1
fi

if [[ ! -d "$GPG_BACKUP_DIR" ]]; then
  echo "Error: GPG backup directory not found: $GPG_BACKUP_DIR" >&2
  exit 1
fi

if [[ ! -f "$BACKUP_FILE" ]]; then
  echo "Error: encrypted backup archive not found: $BACKUP_FILE" >&2
  exit 1
fi

export GPG_TTY="${GPG_TTY:-$(tty)}"
gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true

mkdir -p "$HOME/.gnupg"
chmod 700 "$HOME/.gnupg"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

DECRYPTED_ARCHIVE="$WORK_DIR/gpg-key-backup.tar.gz"
EXTRACT_DIR="$WORK_DIR/extracted"

mkdir -p "$EXTRACT_DIR"

echo "Decrypting backup archive..."
gpg --decrypt \
  --output "$DECRYPTED_ARCHIVE" \
  "$BACKUP_FILE"

echo "Decompressing backup archive..."
tar -xzf "$DECRYPTED_ARCHIVE" -C "$EXTRACT_DIR"

PUBLIC_KEY="$EXTRACT_DIR/public.asc"
PRIVATE_KEY="$EXTRACT_DIR/private.asc"
OWNERTRUST="$EXTRACT_DIR/ownertrust.txt"

if [[ ! -f "$PUBLIC_KEY" ]]; then
  echo "Error: public key not found inside backup archive." >&2
  exit 1
fi

if [[ ! -f "$PRIVATE_KEY" ]]; then
  echo "Error: private key not found inside backup archive." >&2
  exit 1
fi

echo "Importing public key..."
gpg --import "$PUBLIC_KEY"

echo "Importing private key..."
gpg --import "$PRIVATE_KEY"

KEY_FPR="$(
  gpg --list-secret-keys --with-colons --fingerprint |
    awk -F: '
      /^sec:/ { found = 1 }
      found && /^fpr:/ { print $10; exit }
    '
)"

if [[ -z "$KEY_FPR" ]]; then
  echo "Error: could not find imported secret key fingerprint." >&2
  exit 1
fi

echo "Trusting imported key..."
echo "$KEY_FPR:6:" | gpg --import-ownertrust

chmod 700 "$HOME/.gnupg"
find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
find "$HOME/.gnupg" -type d -exec chmod 700 {} \;

echo "Done."
