#!/bin/bash
# Core setup for Ubuntu 24.04+. Run as root (with sudo).
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

# Install basic packages
apt-get -y install gcc stow zsh curl p7zip build-essential software-properties-common unzip wget

# install node and npm
sudo -H -u "$SCRIPT_USER" bash <<EOF
set -e
cd "$SCRIPT_HOME"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source "$SCRIPT_HOME/.nvm/nvm.sh"
nvm install --lts
nvm alias default lts/*
npm install -g tree-sitter-cli
npm install -g @bitwarden/cli
EOF

# install gh cli
(type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) &&
  sudo mkdir -p -m 755 /etc/apt/keyrings &&
  out=$(mktemp) && wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg &&
  cat $out | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null &&
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg &&
  sudo mkdir -p -m 755 /etc/apt/sources.list.d &&
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null &&
  sudo apt update &&
  sudo apt install gh -y

# Install more packages
apt-get -y install tmux
apt-get -y install jq poppler-utils chafa liblua5.1-0-dev python3-venv gpg
apt-get -y install btop vim-gtk3 libfuse2t64
apt-get -y install openssh-server
apt-get -y install bubblewrap
apt-get -y install git-lfs
apt-get -y install gnupg rng-tools
apt-get -y install restic fuse3 sshfs # backups

# install gopass
curl -fsSL https://packages.gopass.pw/repos/gopass/gopass-archive-keyring.gpg \
  -o /usr/share/keyrings/gopass-archive-keyring.gpg

tee /etc/apt/sources.list.d/gopass.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.gopass.pw/repos/gopass
Suites: stable
Architectures: all amd64 arm64 armhf
Components: main
Signed-By: /usr/share/keyrings/gopass-archive-keyring.gpg
EOF
apt update
apt install -y gopass gopass-archive-keyring

# Install required packages for lazyvim
apt-get -y install luarocks npm sqlite3 libsqlite3-dev

# stuff required for some graphical programs
apt-get -y install qt6-wayland libxcb-cursor-dev

# install fastfetch
add-apt-repository -y ppa:zhangsongcui3371/fastfetch
apt-get update
apt-get -y install fastfetch

# install eza
mkdir -p /etc/apt/keyrings
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# Install lazygit
cd "$WORKDIR"
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*') || {
  echo "Failed to determine latest lazygit version (GitHub API rate limit?)"
  exit 1
}
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xzvf lazygit.tar.gz lazygit
install lazygit -D -t /usr/local/bin/

# install imagemagick binary from its website
cd "$WORKDIR"
wget -O magick https://imagemagick.org/archive/binaries/magick
chmod +x magick
mv magick /usr/local/bin

# install fzf from github
cd "$WORKDIR"
git clone --depth 1 https://github.com/junegunn/fzf.git "$WORKDIR/fzf"
"$WORKDIR/fzf/install" --bin
mv "$WORKDIR/fzf/bin/"* /usr/local/bin

# install claude code as user
sudo -H -u "$SCRIPT_USER" bash <<EOF
set -e
curl -fsSL https://claude.ai/install.sh | sh
EOF

# install codex as user
sudo -H -u "$SCRIPT_USER" bash <<EOF
set -e
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
EOF

# install tailscale (system-wide, needs root)
curl -fsSL https://tailscale.com/install.sh | sh

# install rclone (system-wide, needs root; exits 3 when already up to date)
curl -fsSL https://rclone.org/install.sh | bash || [ $? -eq 3 ]

# install neovim from github release
cd "$WORKDIR"
curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
rm -rf /opt/nvim
NVIM_TEMP=$(tar -tzf nvim.tar.gz | head -1 | cut -f1 -d"/")
tar -C /opt -xzvf nvim.tar.gz
mv "/opt/$NVIM_TEMP" "/opt/nvim"
rm nvim.tar.gz

# install uv as user
sudo -H -u "$SCRIPT_USER" bash <<EOF
set -e
curl -LsSf https://astral.sh/uv/install.sh | sh
EOF

# install starship
wget https://starship.rs/install.sh -O - | sh -s -- --yes

# Remove existing files that might conflict with stow
rm -f "$SCRIPT_HOME/.bashrc"
rm -f "$SCRIPT_HOME/.condarc"
rm -f "$SCRIPT_HOME/.zshrc"
rm -f "$SCRIPT_HOME/.gitconfig"
rm -f "$SCRIPT_HOME/.motd_shown"
rm -f "$SCRIPT_HOME/.sudo_as_admin_successful"
rm -rf "$SCRIPT_HOME/.cache/"

# Set zsh as the default shell for the user
chsh -s /bin/zsh "$SCRIPT_USER"

# Apply dotfiles with stow as user
sudo -H -u "$SCRIPT_USER" bash <<EOF
set -e
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME zsh
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME bash
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME git
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME vim
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME nvim
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME starship
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME tmux
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME ssh
EOF
