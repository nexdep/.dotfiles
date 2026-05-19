#!/usr/bin/env bash
set -euo pipefail

GPG_DIR="${GPG_DIR:-$HOME/.dotfiles/gpg}"

KEY_NAME="${GPG_KEY_NAME:-marco}"
KEY_EMAIL="${GPG_KEY_EMAIL:-marco.deppo@hotmail.it}"
KEY_COMMENT="${GPG_KEY_COMMENT:-dotfiles key}"
KEY_EXPIRE="${GPG_KEY_EXPIRE:-0}"

BACKUP_NAME="gpg-key-backup.tar.gz"
ENCRYPTED_BACKUP="$GPG_DIR/$BACKUP_NAME.gpg"

umask 077

mkdir -p "$GPG_DIR"
chmod 700 "$GPG_DIR"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

require_cmd gpg
require_cmd tar
require_cmd mktemp

cleanup() {
  [[ -n "${WORK_DIR:-}" && -d "$WORK_DIR" ]] && rm -rf "$WORK_DIR"
  [[ -n "${PARAMS_FILE:-}" && -f "$PARAMS_FILE" ]] && rm -f "$PARAMS_FILE"
}

trap cleanup EXIT

WORK_DIR="$(mktemp -d)"
PARAMS_FILE="$(mktemp)"

echo "Generating GPG key for: $KEY_NAME <$KEY_EMAIL>"

cat >"$PARAMS_FILE" <<EOF
%echo Generating GPG key
Key-Type: eddsa
Key-Curve: Ed25519
Key-Usage: sign
Subkey-Type: ecdh
Subkey-Curve: Curve25519
Subkey-Usage: encrypt
Name-Real: $KEY_NAME
Name-Comment: $KEY_COMMENT
Name-Email: $KEY_EMAIL
Expire-Date: $KEY_EXPIRE
%ask-passphrase
%commit
%echo Done
EOF

gpg --batch --generate-key "$PARAMS_FILE"

KEY_FPR="$(
  gpg --list-secret-keys --with-colons --fingerprint "$KEY_EMAIL" |
    awk -F: '
      /^sec:/ { found = 1 }
      found && /^fpr:/ { print $10; exit }
    '
)"

if [[ -z "$KEY_FPR" ]]; then
  echo "Could not find generated key for $KEY_EMAIL." >&2
  exit 1
fi

echo "Generated key: $KEY_FPR"

gpg --armor --export "$KEY_FPR" >"$WORK_DIR/public.asc"
gpg --armor --export-secret-keys "$KEY_FPR" >"$WORK_DIR/private.asc"
gpg --armor --export-secret-subkeys "$KEY_FPR" >"$WORK_DIR/private-subkeys.asc"
gpg --export-ownertrust >"$WORK_DIR/ownertrust.txt"

tar -C "$WORK_DIR" \
  --exclude="$BACKUP_NAME" \
  -czf "$WORK_DIR/$BACKUP_NAME" \
  public.asc \
  private.asc \
  private-subkeys.asc \
  ownertrust.txt

gpg --symmetric \
  --cipher-algo AES256 \
  --output "$ENCRYPTED_BACKUP" \
  "$WORK_DIR/$BACKUP_NAME"

chmod 600 "$ENCRYPTED_BACKUP"

echo
echo "Encrypted GPG backup saved to:"
echo "$ENCRYPTED_BACKUP"
echo
echo "Public key fingerprint:"
gpg --fingerprint "$KEY_FPR"
