# Set up the prompt
autoload -Uz promptinit
promptinit
prompt suse
setopt histignorealldups sharehistory


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
alias gtfo="rg \
--color=always --line-number --no-heading \
--smart-case '' $FOAM_TUTORIALS |
fzf --ansi \
--color 'hl:-1:underline,hl+:-1:underline:reverse' \
--delimiter : \
--preview 'batcat -lcpp {1} --highlight-line {2}' \
--preview-window 'up,75%,border,+{2}+3/3,~3'"

# Show contents of the directory after changing to it
chpwd (){ ls -alF; }

# navigation options
setopt  autocd autopushd 

# add to PATH
export PATH="/home/marco/.local/bin:$PATH"
export PATH="/opt/gmsh-git-Linux64/bin/:$PATH"
. /opt/openfoam10/etc/bashrc
export PATH=/mnt/c/Users/marco/AppData/Local/Programs/Microsoft\ VS\ Code/bin:$PATH

export DOTFILES="/mnt/c/Users/marco/OneDrive/Documenti/05_SHARED_SETTINGS/03_DOTFILES_WSL/"
export WORKF="/mnt/c/Users/marco/OneDrive - UNED/01_WORK/"

source /usr/share/doc/fzf/examples/key-bindings.zsh
source /usr/share/doc/fzf/examples/completion.zsh

# use vim keybindings in less
export VISUAL=vim
export EDITOR=vim

# function to print the path in a sorted manner >> start
function showpath() {
    local SORT_FLAG=0

    # Process options
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -s|--sort)
                SORT_FLAG=1
                shift
                ;;
            *)
                echo "Usage: showpath [-s|--sort]"
                return 1
                ;;
        esac
    done

    # Process the PATH variable
    local PATH_OUTPUT
    PATH_OUTPUT=$(echo "$PATH" | sed -e 's/:\([^/]\)/@COLON@\1/g' \
                                     -e 's/:/\n/g' \
                                     -e 's/@COLON@/:/g' \
                                     -e 's/:/ /g')

    if [[ $SORT_FLAG -eq 1 ]]; then
        echo "$PATH_OUTPUT" | sort
    else
        echo "$PATH_OUTPUT"
    fi
}
# function to print the path in a sorted manner >> end

export DISPLAY=:0.0
