# Set up the prompt
autoload -Uz promptinit
promptinit
prompt suse
setopt histignorealldups sharehistory
 
# help with spelling
setopt CORRECT
setopt null_glob
 
#silence bell
unsetopt BEEP

# vim  mode - enter by pressing Esc
setopt vi

bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^?' backward-delete-char



##########
# HISTORY
##########

HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
HISTDUP=erase

# 
setopt APPEND_HISTORY

# Immediately append to history file:
setopt INC_APPEND_HISTORY

# Record timestamp in history:
setopt EXTENDED_HISTORY

# Expire duplicate entries first when trimming history:
setopt HIST_EXPIRE_DUPS_FIRST

# Dont record an entry that was just recorded again:
setopt HIST_IGNORE_DUPS

# Delete old recorded entry if new entry is a duplicate:
setopt HIST_IGNORE_ALL_DUPS

# Do not display a line previously found:
setopt HIST_FIND_NO_DUPS

# Dont record an entry starting with a space:
setopt HIST_IGNORE_SPACE

# Dont write duplicate entries in the history file:
setopt HIST_SAVE_NO_DUPS

# Share history between all sessions:
setopt SHARE_HISTORY

##########
# HISTORY END
##########
 
# Use modern completion system
autoload -Uz compinit && compinit
 
 
 
# Define a custom completer function
_my_number_completer() {
  if [[ $LBUFFER =~ '[0-9]$' ]]; then
    _files -/
  else
    _complete
  fi
}
 
 
zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _my_number_completer _complete
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' menu select=2
eval "$(dircolors -b ~/.dircolors)"
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
zstyle ':completion:*' menu select=long
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*:*:ssh:*:hosts' menu select

zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

#ALIASES
alias ll='eza -ahlF --git --git-repos'
alias la='ls -A'
alias l='ls -CF'
alias clip="clip.exe "
alias start='cmd.exe /c start  '
alias ...='cd ../..'
alias ....='cd ../../..'
alias -s {i,mpi}=nvim
alias jupyter-notebook="~/.local/bin/jupyter-notebook --no-browser"


# use control x for clear screen  >>> start
bindkey '^X' clear-screen

# disable alt/shift-alt + LH
# no-op widget
noop() {}
zle -N noop

# disable Ctrl-L and Ctrl-H
bindkey -r '^L'
bindkey -r '^H'

# disable Alt-H / Alt-L and Alt-Shift-H / Alt-Shift-L
bindkey -r '^[h'
bindkey -r '^[l'
bindkey -r '^[H'
bindkey -r '^[L'

# force them to do nothing in common keymaps
for keymap in emacs viins vicmd; do
  bindkey -M "$keymap" '^[h' noop
  bindkey -M "$keymap" '^[l' noop
  bindkey -M "$keymap" '^[H' noop
  bindkey -M "$keymap" '^[L' noop
done
# use control x for clear screen  <<< end

# Show contents of the directory after changing to it
chpwd (){ eza -ahlF  --git --git-repos; }

# navigation options
setopt  autocd autopushd 

# add to PATH
export PATH="/home/root/.local/bin:$PATH"
export PATH="/opt/nvim/bin:$PATH"
export PATH=/mnt/c/Users/marco/AppData/Local/Programs/Microsoft\ VS\ Code/bin:$PATH
export PATH="$HOME/.local/bin:$PATH"


# use vim keybindings in less
export VISUAL=vim
export EDITOR=vim

# function to simplify the upload of simple repos >> start
acp() {
  # require a commit message
  [ $# -eq 0 ] && { echo "Usage: acp <commit-message>"; return 1; }

  git add -A                       # stage all changes
  git commit -m "$*"               # commit with the given message
  git push -u origin HEAD          # push to the branch you’re currently on
}
# function to simplify the upload of simple repos << end

# function to create and enter a folder >> start
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}
# function to create and enter a folder << end

# function to send the tmux scrollback to neovim >> start
scroll() {
    nvim <(tmux capture-pane -pS - -J \
	               | sed -e :a -e '/^\n*$/{$d;N;};/\n$/ba')
}
# function to send the tmux scrollback to neovim >> end

# bitwarden helpers >> start
_bw_status_value() {
  bw status 2>/dev/null | sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p'
}

_bw_have_session() {
  [[ -n "${BW_SESSION:-}" ]] && bw unlock --check --session "$BW_SESSION" >/dev/null 2>&1
}

_bw_export_session_from() {
  local action="$1"
  local s=""

  case "$action" in
    login)
      s="$(bw login --raw)" || return 1
      ;;
    unlock)
      s="$(bw unlock --raw)" || return 1
      ;;
    *)
      echo "Unknown Bitwarden session action: $action"
      return 1
      ;;
  esac

  if [[ -z "$s" ]]; then
    echo "Bitwarden did not return a session key."
    return 1
  fi

  export BW_SESSION="$s"
}

# function to fetch ssh keys >> start
bw_fetch_ssh() {
  local REF="$1"
  if [[ -z "$REF" ]]; then
    echo "Usage: bw_fetch_ssh <item_id_or_exact_item_name_or_ssh_host>"
    return 1
  fi

  local DEST_DIR="$HOME/.ssh"
  local SSH_CONFIG="$HOME/.ssh/config"
  mkdir -p "$DEST_DIR" && chmod 700 "$DEST_DIR" || return 1

  if ! _bw_have_session; then
    [[ -n "${BW_SESSION:-}" ]] && unset BW_SESSION
    bw_login || return 1
  fi

  if ! _bw_have_session; then
    echo "No valid Bitwarden session available. Run bw_login in an interactive shell."
    return 1
  fi

  bw sync --session "$BW_SESSION" >/dev/null 2>&1 || echo "Warning: bw sync failed; continuing with cached vault data."

  local ITEM_ID=""
  local RESOLVED_NAME="$REF"
  local PRIVATE_KEY=""

  _bw_find_exact_item_id() {
    local name="$1"
    bw list items --search "$name" --session "$BW_SESSION" \
      | jq -r --arg n "$name" '.[] | select(.name == $n) | .id' \
      | head -n 1
  }

  _bw_get_private_key() {
    local item_id="$1"
    local pk=""
    pk="$(bw get item "$item_id" --session "$BW_SESSION" | jq -r '.sshKey.privateKey // empty')" || pk=""
    if [[ -z "$pk" ]]; then
      local att_name
      att_name="$(bw get item "$item_id" --session "$BW_SESSION" | jq -r '.attachments[0].fileName // empty')" || att_name=""
      if [[ -n "$att_name" ]]; then
        pk="$(bw get attachment "$att_name" --itemid "$item_id" --output - --session "$BW_SESSION" 2>/dev/null)"
      fi
    fi
    printf '%s' "$pk"
  }

  # 1) UUID -> direct
  if [[ "$REF" =~ ^[0-9a-fA-F-]{36}$ ]]; then
    ITEM_ID="$REF"
  else
    # 2) exact item name
    ITEM_ID="$(_bw_find_exact_item_id "$REF")"
  fi

  if [[ -n "$ITEM_ID" && "$ITEM_ID" != "null" ]]; then
    PRIVATE_KEY="$(_bw_get_private_key "$ITEM_ID")"
  fi

  # 3) fallback: ssh host alias -> identityfile basename -> bitwarden exact item
  if [[ -z "$PRIVATE_KEY" && "$REF" != "" ]]; then
    local IDENTITY_FILE=""
    local IDENTITY_BASENAME=""

    if [[ -f "$SSH_CONFIG" ]]; then
      IDENTITY_FILE="$(
        ssh -G -F "$SSH_CONFIG" "$REF" 2>/dev/null \
          | grep '^identityfile ' \
          | tail -n 1 \
          | sed 's/^identityfile //'
      )"
    else
      IDENTITY_FILE="$(
        ssh -G "$REF" 2>/dev/null \
          | grep '^identityfile ' \
          | tail -n 1 \
          | sed 's/^identityfile //'
      )"
    fi

    if [[ -n "$IDENTITY_FILE" ]]; then
      IDENTITY_FILE="${IDENTITY_FILE/#\~/$HOME}"
      IDENTITY_BASENAME="$(basename "$IDENTITY_FILE")"

      if [[ -n "$IDENTITY_BASENAME" ]]; then
        ITEM_ID="$(_bw_find_exact_item_id "$IDENTITY_BASENAME")"
        if [[ -n "$ITEM_ID" && "$ITEM_ID" != "null" ]]; then
          PRIVATE_KEY="$(_bw_get_private_key "$ITEM_ID")"
          if [[ -n "$PRIVATE_KEY" ]]; then
            RESOLVED_NAME="$IDENTITY_BASENAME"
          fi
        fi
      fi
    fi
  fi

  if [[ -z "$ITEM_ID" || "$ITEM_ID" == "null" ]]; then
    echo "Couldn't find an item with exact name: $REF"
    echo "Also checked SSH-resolved IdentityFile and found no matching Bitwarden item."
    return 1
  fi

  if [[ -z "$PRIVATE_KEY" ]]; then
    echo "Found Bitwarden item, but no SSH private key found in it."
    echo "Checked .sshKey.privateKey and attachments[0]."
    return 1
  fi

  local RAW_NAME BASENAME
  RAW_NAME="$(bw get item "$ITEM_ID" --session "$BW_SESSION" | jq -r '.name // "bitwarden_key"')" || return 1
  BASENAME="${RAW_NAME// /_}"
  BASENAME="${BASENAME//[^A-Za-z0-9._-]/_}"
  [[ -z "$BASENAME" ]] && BASENAME="bitwarden_key"

  local DEST_PATH="$DEST_DIR/$BASENAME"
  if [[ -e "$DEST_PATH" ]]; then
    local N=1
    while [[ -e "${DEST_PATH}.frombw.$N" ]]; do ((N++)); done
    DEST_PATH="${DEST_PATH}.frombw.$N"
  fi

  umask 077
  printf '%s\n' "$PRIVATE_KEY" > "$DEST_PATH" || return 1
  chmod 600 "$DEST_PATH"

  if ! ssh-keygen -y -f "$DEST_PATH" > "${DEST_PATH}.pub" 2>/dev/null; then
    echo "Wrote private key, but failed to derive public key (bad key format or needs passphrase)."
    return 1
  fi
  chmod 644 "${DEST_PATH}.pub"

  echo "Fetched Bitwarden item: $RAW_NAME"
  [[ "$RESOLVED_NAME" != "$REF" ]] && echo "Resolved via SSH host '$REF' -> IdentityFile basename '$RESOLVED_NAME'"
  echo "Private key: $DEST_PATH"
  echo "Public  key: ${DEST_PATH}.pub"
}
# function to fetch ssh keys << end

# function to login or  unlock bitwarden and store the session >>> start
bw_login() {
  # Options:
  #   --no-relock : if status is unlocked but BW_SESSION missing, fail instead of lock+unlock
  local no_relock=0
  if [ "${1:-}" = "--no-relock" ]; then
    no_relock=1
  fi

  if ! command -v bw >/dev/null 2>&1; then
    echo "Could not find the Bitwarden CLI (bw) on PATH."
    return 1
  fi

  # Get status string from bw status JSON (no jq required)
  local st
  st="$(_bw_status_value)"

  if [ -z "$st" ]; then
    echo "Could not read bw status. Is the Bitwarden CLI installed and on PATH?"
    return 1
  fi

  case "$st" in
    unauthenticated)
      # login and capture session key
      _bw_export_session_from login || return 1
      echo "BW_SESSION exported (login)."
      ;;

    locked)
      # unlock and capture session key
      _bw_export_session_from unlock || return 1
      echo "BW_SESSION exported (unlock)."
      ;;

    unlocked)
      # if already have a session in env, we're good
      if _bw_have_session; then
        echo "Vault is unlocked; BW_SESSION already set."
        return 0
      fi
      [[ -n "${BW_SESSION:-}" ]] && unset BW_SESSION

      # Otherwise, BW doesn't provide a way to retrieve it from the unlocked state reliably.
      if [ $no_relock -eq 1 ]; then
        echo "Vault is unlocked but BW_SESSION is not set. Re-run without --no-relock to lock+unlock."
        return 1
      fi

      # Force a fresh session key
      bw lock >/dev/null 2>&1
      _bw_export_session_from unlock || return 1
      echo "BW_SESSION exported (forced lock+unlock)."
      ;;

    *)
      echo "Unknown status: $st"
      return 1
      ;;
  esac
}
# function to login or  unlock bitwarden and store the session <<< end
# bitwarden helpers << end


# function to print the path in a sorted manner >> start
# Usage: showpath [VAR_NAME] [-s|--sort]
# - Defaults to "PATH" if no variable name is given.
# - If VAR_NAME is an array (e.g. fpath), each element is printed on its own line.
# - If VAR_NAME is colon-separated (e.g. PATH), each : delimited entry is printed on its own line.
# - If VAR_NAME is space-delimited (sometimes fpath is set this way), splits on whitespace.
# - -s or --sort sorts the output.
function showpath() {
    local SORT_FLAG=0
    local varName="PATH"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--sort)
                SORT_FLAG=1
                shift
                ;;
            -*)
                echo "Usage: showpath [VAR_NAME] [-s|--sort]"
                return 1
                ;;
            *)
                varName="$1"
                shift
                ;;
        esac
    done

    local rawValue=${(P)varName}   # Raw contents of the variable
    local -a paths

    # 1) Check if it's truly an array (the user declared 'typeset -a varName' or 'varName=(...)')
    if [[ ${(t)varName} == *array* ]]; then
        # Expanding a real array
        paths=( ${(P)varName} )
    else
        # 2) If it's not flagged as an array, we guess how it's separated
        if [[ "$rawValue" == *:* ]]; then
            # Colon-separated (like PATH)
            paths=( ${(s/:/)rawValue} )
        else
            # Space-delimited (e.g. fpath="/usr/share/zsh/... /usr/local/share/...") 
            paths=( ${(s/ /)rawValue} )
        fi
    fi

    # Sort if requested
    if (( SORT_FLAG )); then
        printf '%s\n' "${paths[@]}" | sort
    else
        printf '%s\n' "${paths[@]}"
    fi
}
# function to print the path in a sorted manner >> end

# function to search file and paths
# cf - fuzzy cd from anywhere
# ex: cf word1 word2 ... (even part of a file name)
# zsh autoload function
cf() {
  local file

  file="$(locate -Ai -0 $@ | grep -z -vE '~$' | fzf --read0 -0 -1)"

  if [[ -n $file ]]
  then
     if [[ -d $file ]]
     then
        cd -- $file
     else
        cd -- ${file:h}
     fi
  fi
}
# function end



# starship
eval "$(starship init zsh)"

#Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

export DISPLAY=:0.0

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# autopull dotfiles - start
stamp="$HOME/.cache/dotfiles-last-pull"
dotfiles="$HOME/.dotfiles"

mkdir -p "$HOME/.cache"

if [ ! -f "$stamp" ] || [ "$(find "$stamp" -mmin +720 2>/dev/null)" ]; then
  {
    git -C "$dotfiles" fetch --quiet &&
    git -C "$dotfiles" diff --quiet &&
    git -C "$dotfiles" diff --cached --quiet &&
    git -C "$dotfiles" pull --ff-only --quiet &&
    touch "$stamp"
  } >/dev/null 2>&1 &!
fi
# autopull dotfiles - end



# lazy load nvm - start
export NVM_DIR="$HOME/.nvm"

_load_nvm() {
  unset -f nvm node npm npx corepack
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
}

nvm() {
  _load_nvm
  nvm "$@"
}

node() {
  _load_nvm
  node "$@"
}

npm() {
  _load_nvm
  npm "$@"
}

npx() {
  _load_nvm
  npx "$@"
}

corepack() {
  _load_nvm
  corepack "$@"
}
# lazy load nvm - end

export DFILES="$HOME/.dotfiles"

# local zsh sourcing
source_if_exists() {
  [[ -f "$1" ]] && source "$1"
}


source_if_exists "$HOME/.zsh/wsl_neutronics.zsh"
source_if_exists "$HOME/.config/secrets.env"


# Auto-start tmux for local interactive terminals only
# Skip if already in tmux, over SSH, inside VS Code, or inside Neovim terminal
if [[ -z "$TMUX" \
   && -n "$PS1" \
   && -z "$SSH_CONNECTION" \
   && "$TERM_PROGRAM" != "vscode" \
   && -z "$NVIM" ]]; then
  tmux attach-session -t main || tmux new-session -s main
fi
