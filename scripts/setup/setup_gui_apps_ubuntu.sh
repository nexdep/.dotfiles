#!/usr/bin/env bash
set -euo pipefail

# Installs GUI applications on Ubuntu for a regular desktop user.
# Current app set: WezTerm, Obsidian, Visual Studio Code Insiders,
# Firefox Developer Edition, Thunderbird Beta, Chromium, ParaView, Slack,
# Zoom, and Zotero.

if [[ ${EUID} -eq 0 ]]; then
  echo "Run this script as your regular user, not as root. It will use sudo when needed." >&2
  exit 1
fi

if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
else
  echo "Cannot detect the operating system because /etc/os-release is missing." >&2
  exit 1
fi

if [[ ${ID:-} != "ubuntu" && ${ID_LIKE:-} != *"ubuntu"* && ${ID_LIKE:-} != *"debian"* ]]; then
  echo "This script is intended for Ubuntu or Ubuntu-like Debian systems." >&2
  exit 1
fi

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found after prerequisite install: $1" >&2
    exit 1
  fi
}

sudo_keepalive() {
  sudo -v
  while true; do
    sudo -n true
    sleep 60
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill "${SUDO_KEEPALIVE_PID}" 2>/dev/null || true' EXIT
}

install_prerequisites() {
  sudo apt-get update
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    flatpak \
    gpg \
    snapd \
    wget \
    xz-utils
}

configure_wezterm_repo() {
  echo "Configuring WezTerm apt repository..."
  curl -fsSL https://apt.fury.io/wez/gpg.key \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | sudo tee /etc/apt/sources.list.d/wezterm.list >/dev/null
  sudo chmod 0644 /usr/share/keyrings/wezterm-fury.gpg
}

configure_vscode_repo() {
  echo "Configuring Visual Studio Code Insiders apt repository..."
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | sudo gpg --yes --dearmor -o /usr/share/keyrings/microsoft.gpg
  sudo chmod 0644 /usr/share/keyrings/microsoft.gpg

  sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: amd64,arm64,armhf
Signed-By: /usr/share/keyrings/microsoft.gpg
EOF

  sudo tee /etc/apt/preferences.d/code-insiders >/dev/null <<'EOF'
Package: code-insiders
Pin: origin "packages.microsoft.com"
Pin-Priority: 9999
EOF
}

configure_mozilla_repo() {
  echo "Configuring Mozilla apt repository..."
  sudo install -d -m 0755 /etc/apt/keyrings
  wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- \
    | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc >/dev/null

  local fingerprint
  fingerprint="$(gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc \
    | awk '/pub/{getline; gsub(/^ +| +$/, ""); print; exit}')"

  if [[ "${fingerprint}" != "35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3" ]]; then
    echo "Mozilla signing key fingerprint verification failed: ${fingerprint}" >&2
    exit 1
  fi

  sudo tee /etc/apt/sources.list.d/mozilla.sources >/dev/null <<'EOF'
Types: deb
URIs: https://packages.mozilla.org/apt
Suites: mozilla
Components: main
Signed-By: /etc/apt/keyrings/packages.mozilla.org.asc
EOF

  sudo tee /etc/apt/preferences.d/mozilla >/dev/null <<'EOF'
Package: *
Pin: origin packages.mozilla.org
Pin-Priority: 1000
EOF
}

install_apt_apps() {
  echo "Installing WezTerm, Visual Studio Code Insiders, Firefox Developer Edition, and ParaView..."
  sudo apt-get update
  sudo apt-get install -y wezterm code-insiders firefox-devedition paraview
}

install_obsidian_flatpak() {
  echo "Installing Obsidian from Flathub for user ${USER}..."
  need_cmd flatpak
  flatpak remote-add --if-not-exists --user flathub https://dl.flathub.org/repo/flathub.flatpakrepo
  flatpak install -y --user flathub md.obsidian.Obsidian
}

install_snap_app() {
  local app_name="$1"

  need_cmd snap
  if snap list "${app_name}" >/dev/null 2>&1; then
    echo "${app_name} snap is already installed."
  else
    echo "Installing ${app_name} from Snap..."
    sudo snap install "${app_name}"
  fi
}

install_zoom_deb() {
  local arch
  arch="$(dpkg --print-architecture)"

  if [[ "${arch}" != "amd64" ]]; then
    echo "Zoom DEB install is only configured for amd64; current architecture is ${arch}." >&2
    exit 1
  fi

  echo "Installing Zoom from the latest Zoom DEB..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local deb_path="${tmp_dir}/zoom_amd64.deb"

  curl -fL https://zoom.us/client/latest/zoom_amd64.deb -o "${deb_path}"
  sudo apt-get install -y "${deb_path}"
  rm -rf "${tmp_dir}"
}

install_thunderbird_beta() {
  local arch
  arch="$(dpkg --print-architecture)"

  if [[ "${arch}" != "amd64" ]]; then
    echo "Thunderbird Beta binary install is only configured for amd64; current architecture is ${arch}." >&2
    exit 1
  fi

  echo "Installing Thunderbird Beta from the latest official Linux binary..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local archive_path="${tmp_dir}/thunderbird-beta.tar.xz"

  curl -fL "https://download.mozilla.org/?product=thunderbird-beta-latest-SSL&os=linux64&lang=en-US" \
    -o "${archive_path}"
  tar -xJf "${archive_path}" -C "${tmp_dir}"

  sudo rm -rf /opt/thunderbird-beta
  sudo mv "${tmp_dir}/thunderbird" /opt/thunderbird-beta
  sudo ln -sf /opt/thunderbird-beta/thunderbird /usr/local/bin/thunderbird-beta

  local icon_path="/opt/thunderbird-beta/chrome/icons/default/default128.png"
  if [[ ! -f "${icon_path}" ]]; then
    icon_path="/opt/thunderbird-beta/default128.png"
  fi

  sudo tee /usr/share/applications/thunderbird-beta.desktop >/dev/null <<EOF
[Desktop Entry]
Name=Thunderbird Beta
Comment=Read and write email with Thunderbird Beta
Exec=/opt/thunderbird-beta/thunderbird %u
Icon=${icon_path}
Terminal=false
Type=Application
Categories=Network;Email;
MimeType=x-scheme-handler/mailto;message/rfc822;
StartupNotify=true
StartupWMClass=thunderbird-beta
EOF

  rm -rf "${tmp_dir}"
}

install_zotero() {
  local arch
  arch="$(dpkg --print-architecture)"

  local platform
  case "${arch}" in
    amd64)
      platform="linux-x86_64"
      ;;
    arm64)
      platform="linux-arm64"
      ;;
    *)
      echo "Zotero binary install is only configured for amd64 and arm64; current architecture is ${arch}." >&2
      exit 1
      ;;
  esac

  echo "Installing Zotero from the latest official Linux binary..."
  local tmp_dir
  tmp_dir="$(mktemp -d)"
  local archive_path="${tmp_dir}/zotero.tar.xz"
  local extracted_dir

  curl -fL "https://www.zotero.org/download/client/dl?channel=release&platform=${platform}" \
    -o "${archive_path}"
  extracted_dir="$(tar -tf "${archive_path}" | sed -n '1s#/.*##p')"
  tar -xJf "${archive_path}" -C "${tmp_dir}"

  if [[ -z "${extracted_dir}" || ! -d "${tmp_dir}/${extracted_dir}" ]]; then
    echo "Could not find extracted Zotero directory." >&2
    rm -rf "${tmp_dir}"
    exit 1
  fi

  sudo rm -rf /opt/zotero
  sudo mv "${tmp_dir}/${extracted_dir}" /opt/zotero
  sudo ln -sf /opt/zotero/zotero /usr/local/bin/zotero

  if [[ -x /opt/zotero/set_launcher_icon ]]; then
    sudo /opt/zotero/set_launcher_icon
  fi

  mkdir -p "${HOME}/.local/share/applications"
  ln -sfn /opt/zotero/zotero.desktop "${HOME}/.local/share/applications/zotero.desktop"

  rm -rf "${tmp_dir}"
}

main() {
  sudo_keepalive
  install_prerequisites
  need_cmd curl
  need_cmd gpg
  need_cmd snap
  need_cmd wget

  configure_wezterm_repo
  configure_vscode_repo
  configure_mozilla_repo
  install_apt_apps
  install_obsidian_flatpak
  install_snap_app chromium
  install_snap_app slack
  install_zoom_deb
  install_thunderbird_beta
  install_zotero

  echo
  echo "Done. Installed apps:"
  echo "  - wezterm"
  echo "  - code-insiders"
  echo "  - firefox-devedition"
  echo "  - thunderbird-beta"
  echo "  - paraview"
  echo "  - chromium via Snap"
  echo "  - slack via Snap"
  echo "  - zoom"
  echo "  - zotero"
  echo "  - md.obsidian.Obsidian via Flatpak"
  echo
  echo "If Obsidian does not appear in the app launcher immediately, log out and back in."
}

main "$@"
