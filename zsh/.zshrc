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

# gomi alias for removing files
if command -v gomi >/dev/null 2>&1; then
  alias gm='gomi'
fi

# Show contents of the directory after changing to it
chpwd (){ eza -ahlF  --git --git-repos; }

# Show contents of the directory after changing to it
explorer() {
  local target="${1:-.}"             # default to current dir
  /mnt/c/Windows/explorer.exe "$(wslpath -w "$target")"
}


# navigation options
setopt  autocd autopushd 

# add to PATH
export PATH="/home/root/.local/bin:$PATH"
export PATH="/opt/nvim/bin:$PATH"
export PATH=/mnt/c/Users/marco/AppData/Local/Programs/Microsoft\ VS\ Code/bin:$PATH

export DOTFILES="/mnt/c/Users/marco/OneDrive/Documenti/05_SHARED_SETTINGS/03_DOTFILES_WSL/"
export WORKF="/mnt/c/Users/marco/OneDrive - UNED/01_WORK/"

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



# starship
eval "$(starship init zsh)"

#Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

export DISPLAY=:0.0

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

. "$HOME/.local/bin/env"

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

# end


export PATH="$PATH:$HOME/.local/bin"

#zoxide part
eval "$(zoxide init zsh)"
alias cd="z"

# import secrets.env
[ -f ~/.config/secrets.env ] && source ~/.config/secrets.env


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
source "$HOME/.cargo/env"
export OPENMC_CROSS_SECTIONS="$HOME/openmc_data/endfb-viii.0-hdf5/cross_sections.xml"
export OPENMC_CHAIN_FILE="$HOME/openmc_data/chain_endfb81_fast/chain_endfb81_fast.xml"

