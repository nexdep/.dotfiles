
# lazy load openfoam12
of12() {
  . /opt/openfoam12/etc/bashrc
}

export OPENMC_CROSS_SECTIONS="$HOME/openmc_data/endfb-viii.1-hdf5/cross_sections.xml"
export OPENMC_CHAIN_FILE="$HOME/openmc_data/chain_endfb81_fast/chain_endfb81_fast.xml"
export ENDFB81_XS="$HOME/openmc_data/endfb-viii.1-hdf5/cross_sections.xml"

#zoxide part
eval "$(zoxide init zsh)"
alias cd="z"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/marco/miniforge3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/marco/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/home/marco/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/home/marco/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# launcher function for yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
# function end

# --- WSL path helpers ---------------------------------------------------------
wsl_path() {
  local p="$1"

  # Windows drive path: C:\...
  # UNC path: \\server\share
  if [[ "$p" == [A-Za-z]:\\* || "$p" == \\\\* ]]; then
    wslpath -u "$p"
  else
    printf '%s\n' "$p"
  fi
}

_wsl_wrap_cmd() {
  local cmd="$1"
  shift

  local args=()
  for arg in "$@"; do
    if [[ "$arg" == [A-Za-z]:\\* || "$arg" == \\\\* || "$arg" == /* || "$arg" == ./* || "$arg" == ../* ]]; then
      args+=("$(wsl_path "$arg")")
    else
      args+=("$arg")
    fi
  done

  "$cmd" "${args[@]}"
}

cpwsl() {
  _wsl_wrap_cmd cp "$@"
}

mvwsl() {
  _wsl_wrap_cmd mv "$@"
}

cdwsl() {
  cd "$(wsl_path "$1")"
}

# Examples:
# cpwsl 'C:\Users\marco\file.pdf' .
# cpwsl -r 'C:\Users\marco\project' ./backup
# mvwsl file.txt 'C:\Users\marco\Desktop'
# cdwsl 'C:\Users\marco\Desktop'

# open explorer in the current directory
explorer() {
  local target="${1:-.}"             # default to current dir
  /mnt/c/Windows/explorer.exe "$(wslpath -w "$target")"
}

# --- Clipboard helpers for WSL2 ---
# Send text to Windows clipboard
clipboard-copy() {
    print -rn -- "$1" | clip.exe
}

# Widget: yy  (copy line)
zle-clipboard-yank-line() {
    clipboard-copy "$BUFFER"
}
zle -N zle-clipboard-yank-line
bindkey -M vicmd 'yy' zle-clipboard-yank-line

# Widget: dd (delete line + copy)
zle-clipboard-delete-line() {
    clipboard-copy "$BUFFER"
    BUFFER=""
    CURSOR=0
}
zle -N zle-clipboard-delete-line
bindkey -M vicmd 'dd' zle-clipboard-delete-line

# Widget: p  (paste clipboard into buffer)
zle-clipboard-paste() {
    # Get Windows clipboard content
    local clip="$(powershell.exe -NoProfile -Command Get-Clipboard | tr -d '\r')"
    BUFFER="${BUFFER[1,CURSOR]}${clip}${BUFFER[CURSOR+1,-1]}"
    CURSOR=$(( CURSOR + ${#clip} ))
}
zle -N zle-clipboard-paste
bindkey -M vicmd 'p' zle-clipboard-paste

# gomi alias for removing files
if command -v gomi >/dev/null 2>&1; then
  alias gm='gomi'
fi
