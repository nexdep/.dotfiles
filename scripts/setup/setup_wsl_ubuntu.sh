#!/bin/bash
# WSL setup for Ubuntu 24.04+. Run as root (with sudo).
#
########################################################
#
# install this script after running setup_laptop_ubuntu.sh
#
########################################################
set -e

if [ "$EUID" -ne 0 ]; then
  echo "Please run this script as root or use sudo."
  exit 1
fi

SCRIPT_USER="marco"
SCRIPT_HOME="/home/$SCRIPT_USER"

if ! id "$SCRIPT_USER" >/dev/null 2>&1; then
  echo "User '$SCRIPT_USER' does not exist."
  exit 1
fi

if [ ! -d "$SCRIPT_HOME" ]; then
  echo "Home directory '$SCRIPT_HOME' does not exist."
  exit 1
fi

LOG_FILE="$SCRIPT_HOME/ubuntu_install.log"
touch "$LOG_FILE"
chown "$SCRIPT_USER:$SCRIPT_USER" "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Temporary directory for downloads, so failures don't leave root-owned files in $SCRIPT_HOME
WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Update and upgrade the system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean -y

# Apply dotfiles with stow as user
sudo -H -u "$SCRIPT_USER" bash <<EOF
set -e
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME wsl
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME zsh_wsl_neutronics
EOF
