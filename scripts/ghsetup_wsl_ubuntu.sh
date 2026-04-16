#!/bin/bash
# Ensure the script is run as root (with sudo)
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
apt-get -y install gcc stow zsh curl p7zip build-essential software-properties-common unzip

# install node and npm
cd "$SCRIPT_HOME"
sudo -H -u "$SCRIPT_USER" bash <<EOF
cd "$SCRIPT_HOME"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source "$SCRIPT_HOME/.nvm/nvm.sh"
nvm install --lts
nvm alias default lts/*
npm install -g tree-sitter-cli
npm install -g @openai/codex
npm install -g @bitwarden/cli
EOF

# Install more packages
apt-get -y install ffmpeg pandoc fd-find ripgrep tmux
apt-get -y install jq poppler-utils chafa liblua5.1-0-dev python3-venv gpg
apt-get -y install btop vim-gtk3 libfuse2t64
apt-get -y install openssh-server
apt-get -y install bubblewrap
apt-get -y install git-lfs

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
wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | tee /etc/apt/sources.list.d/gierens.list
sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
sudo apt update
sudo apt install -y eza

# Install lazygit
cd "$SCRIPT_HOME"
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | \grep -Po '"tag_name": *"v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xzvf lazygit.tar.gz lazygit
sudo install lazygit -D -t /usr/local/bin/
rm lazygit
rm lazygit.tar.gz

# install imagemagick binary from its website
cd "$SCRIPT_HOME"
wget https://imagemagick.org/archive/binaries/magick
chmod +x magick
mv magick /usr/local/bin

# install fzf from github
cd "$SCRIPT_HOME"
git clone --depth 1 https://github.com/junegunn/fzf.git "$SCRIPT_HOME/.fzf"
"$SCRIPT_HOME/.fzf/install" --bin
mv "$SCRIPT_HOME/.fzf/bin/"* /usr/local/bin
rm -rf "$SCRIPT_HOME/.fzf/"

# install miniforge
sudo -H -u "$SCRIPT_USER" bash <<EOF
cd "$SCRIPT_HOME"
curl -L -o miniforge.sh \
  "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash miniforge.sh -b -p "$SCRIPT_HOME/miniforge3"
rm miniforge.sh
EOF

# install claude code as user
sudo -u "$SCRIPT_USER" bash <<EOF
curl -fsSL https://claude.ai/install.sh | sh
EOF

# install neovim from github release
cd "$SCRIPT_HOME"
curl -Lo nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
rm -rf /opt/nvim
NVIM_TEMP=$(tar -tzf nvim.tar.gz | head -1 | cut -f1 -d"/")
tar -C /opt -xzvf nvim.tar.gz
mv "/opt/$NVIM_TEMP" "/opt/nvim"
rm nvim.tar.gz

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

# install uv and llm as user
sudo -u "$SCRIPT_USER" bash <<EOF
export HOME="$SCRIPT_HOME"
export PATH="$SCRIPT_HOME/.local/bin:$PATH"
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$SCRIPT_HOME/.local/bin:$PATH"
uv tool install llm
EOF

# install starship
wget https://starship.rs/install.sh -O - | sh -s -- --yes

# install gomi as user
curl -fsSL https://gomi.dev/install | PREFIX=/usr/local/bin bash

# Remove existing files that might conflict with stow
rm -f "$SCRIPT_HOME/.bashrc"
rm -f "$SCRIPT_HOME/.condarc"
rm -f "$SCRIPT_HOME/.zshrc"
rm -f "$SCRIPT_HOME/.gitconfig"
rm -f "$SCRIPT_HOME/.motd_shown"
rm -f "$SCRIPT_HOME/.sudo_as_admin_successful"
rm -rf "$SCRIPT_HOME/.cache/"

# Install zoxide as user
sudo -u "$SCRIPT_USER" bash <<EOF
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
EOF

# Set zsh as the default shell for the user by directly editing /etc/passwd
sed -i -E "s|^($SCRIPT_USER:[^:]+:[0-9]+:[0-9]+:[^:]*:[^:]+):[^:]+|\1:/bin/zsh|" /etc/passwd

# Apply dotfiles with stow as user
sudo -u "$SCRIPT_USER" bash <<EOF
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME zsh
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME bash
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME wsl
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME conda
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME git
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME vim
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME nvim
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME yazi
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME starship
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME tmux
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME gomi
stow -v --dir=$SCRIPT_HOME/.dotfiles --target=$SCRIPT_HOME ssh
EOF
