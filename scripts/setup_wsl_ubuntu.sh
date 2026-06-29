#!/bin/bash
# Ensure the script is run as root (with sudo)
#
########################################################
#
# install this script after running setup_core_ubuntu.sh
#
########################################################
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

# Update and upgrade the system
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get autoremove -y
apt-get autoclean -y

# Install basic packages
apt-get -y install gcc stow zsh curl p7zip build-essential software-properties-common unzip wget

apt-get -y install ffmpeg pandoc fd-find ripgrep

# install miniforge
sudo -H -u "$SCRIPT_USER" bash <<EOF
cd "$SCRIPT_HOME"
curl -L -o miniforge.sh \
  "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash miniforge.sh -b -p "$SCRIPT_HOME/miniforge3"
rm miniforge.sh
EOF

# install yazi latest
cd "$SCRIPT_HOME"
wget -qO yazi.zip https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip
7z x yazi.zip -o./yazi-temp
mv yazi-temp/*/yazi /usr/local/bin
mv yazi-temp/*/ya /usr/local/bin
mv yazi-temp/*/completions/_ya /usr/local/share/zsh/site-functions
mv yazi-temp/*/completions/_yazi /usr/local/share/zsh/site-functions
rm -rf yazi-temp yazi.zip

# install ripgrep-all
cd "$SCRIPT_HOME"
RGA_VERSION=$(curl -s "https://api.github.com/repos/phiresky/ripgrep-all/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
echo "Fetched RGA_VERSION: $RGA_VERSION"
curl -Lo rga.tar.gz "https://github.com/phiresky/ripgrep-all/releases/download/v${RGA_VERSION}/ripgrep_all-v${RGA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
echo "constructed url: https://github.com/phiresky/ripgrep-all/releases/download/v${RGA_VERSION}/ripgrep_all-v${RGA_VERSION}-x86_64-unknown-linux-musl.tar.gz"
mkdir -p rga-folder
tar xzvf rga.tar.gz -C ./rga-folder
mv ./rga-folder/*/rga /usr/local/bin
mv ./rga-folder/*/rga-fzf /usr/local/bin
mv ./rga-folder/*/rga-preproc /usr/local/bin
rm -rf ./rga-folder/
rm rga.tar.gz

# install gomi as user
curl -fsSL https://gomi.dev/install | PREFIX=/usr/local/bin bash

# Install zoxide as user
sudo -u "$SCRIPT_USER" bash <<EOF
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
EOF

# Apply dotfiles with stow as user
sudo -u "$SCRIPT_USER" bash <<EOF
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME wsl
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME conda
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME yazi
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME gomi
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME zsh_wsl_neutronics
EOF
