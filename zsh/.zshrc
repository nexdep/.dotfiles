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
compinit

zstyle ':completion:*' auto-description 'specify: %d'
zstyle ':completion:*' completer _expand _complete _correct _approximate
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
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

#ALIASES
alias ll='ls -AhlF'
alias la='ls -A'
alias l='ls -CF'
alias explorer="explorer.exe "
alias vim="nvim"
alias vi="\vim"
alias start='cmd.exe /c start  '
alias -s {i,mpi}=nvim
alias jupyter-notebook="~/.local/bin/jupyter-notebook --no-browser"

# Show contents of the directory after changing to it
chpwd (){ ls -alF; }

# navigation options
setopt  autocd autopushd 

# add to PATH
export PATH="/home/marco/.local/bin:$PATH"
export PATH="/home/root/.local/bin:$PATH"
export PATH="/opt/nvim-linux64/bin:$PATH"
export PATH=/mnt/c/Users/marco/AppData/Local/Programs/Microsoft\ VS\ Code/bin:$PATH

export DOTFILES="/mnt/c/Users/marco/OneDrive/Documenti/05_SHARED_SETTINGS/03_DOTFILES_WSL/"
export WORKF="/mnt/c/Users/marco/OneDrive - UNED/01_WORK/"

source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

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

# function to print the path in a sorted manner >> start
# Use: showpath [VAR_NAME] [-s|--sort]
# Defaults to "PATH" if no variable name is provided
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

    # Get the actual content of the chosen variable
    local varContent=${(P)varName}  # Zsh 'parameter expansion' to get $PATH, $fpath, etc.

    # Convert colon-separated paths to lines, preserving any paths with colons in them
    local PATH_OUTPUT
    PATH_OUTPUT=$(
        echo "$varContent" \
        | sed -e 's/:\([^/]\)/@COLON@\1/g' \
              -e 's/:/\n/g' \
              -e 's/@COLON@/:/g' \
              -e 's/:/ /g'
    )

    # If sort flag is on, sort the lines
    if [[ $SORT_FLAG -eq 1 ]]; then
        echo "$PATH_OUTPUT" | sort
    else
        echo "$PATH_OUTPUT"
    fi
}
# function to print the path in a sorted manner >> end

#zoxide part
eval "$(zoxide init zsh)"
alias cd="z"

export DISPLAY=:0.0
