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

# Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
HISTSIZE=1000
SAVEHIST=1000
HISTFILE=~/.zsh_history
 
# Use modern completion system
autoload -Uz compinit
if ! type compinit &>/dev/null; then
  compinit
fi
 
 
 
# Define a custom completer function
_my_number_completer() {
  if [[ $LBUFFER =~ '[0-9]$' ]]; then
    _files -/
  else
    _complete
  fi
}
 
 
zstyle ':completion:*' auto-description 'specify: %d'
#zstyle ':completion:*' completer _my_number_completer _expand _complete _correct _approximate
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
alias explorer="explorer.exe "
alias clip="clip.exe "
alias start='cmd.exe /c start  '
alias ...='cd ../..'
alias -s {i,mpi}=nvim
alias jupyter-notebook="~/.local/bin/jupyter-notebook --no-browser"

# Show contents of the directory after changing to it
chpwd (){ eza -ahlF  --git --git-repos; }

# navigation options
setopt  autocd autopushd 

# add to PATH
export PATH="/home/marco/.local/bin:$PATH"
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
    git add -A
    git commit -m "$1"
    git push origin main
}
# function to simplify the upload of simple repos << end

# function to create and enter a folder >> start
mkcd() {
  mkdir -p -- "$1" && cd -- "$1"
}
# function to create and enter a folder << end

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


#zoxide part
eval "$(zoxide init zsh)"
alias cd="z"

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
