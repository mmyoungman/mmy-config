#
# ~/.bashrc
#

stty -ixon # Disable ctrl-s and ctrl-q
shopt -s autocd # cd into dir by typing dir name
HISTSIZE= HISTFILESIZE= # Infinite history

unameOut="$(uname -s)"
case $unameOut in
   Linux*) machine="linux";;
   Darwin*) machine="mac";;
   *)
      echo ".bashrc says: Unsupported OS detected!"
      ;;
esac

# Use nvim, if available
[ -f /usr/bin/nvim ] && alias vim=nvim
[ -f /usr/bin/nvim ] && EDITOR=/usr/bin/nvim

# Git stuff
GIT_DIR=~/.config/git
if [ ! -d $GIT_DIR ]; then
    mkdir -p $GIT_DIR
fi

GIT_PROMPT=$GIT_DIR/git-prompt.sh
if [ ! -f $GIT_PROMPT ]; then
    curl -o $GIT_PROMPT 'https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh'
fi
source $GIT_PROMPT

GIT_COMPLETION=$GIT_DIR/git-completion.bash
if [ ! -f $GIT_COMPLETION ]; then
    curl -o $GIT_COMPLETION 'https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash'
fi
source $GIT_COMPLETION

# Git aliases
alias gst="git status"
__git_complete gst _git_status
alias gdi="git diff"
__git_complete gdi _git_diff
alias gpl="git pull --rebase"
__git_complete gpl _git_pull
alias gph="git push"
__git_complete gph _git_push
alias gad="git add"
__git_complete gad _git_add
alias gcm="git commit"
__git_complete gcm _git_commit
alias gco="git checkout"
__git_complete gco _git_checkout
alias grb="git rebase"
__git_complete grb _git_rebase
alias glg="git log --oneline -n 20"
__git_complete glg _git_log

alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias la='ls -al --color=auto'
alias sdn='shutdown now'

alias dotnetall='dotnet clean; dotnet build; dotnet run'
alias dfe-data-processor='func host start --port 7071 --pause-on-error'
alias dfe-publisher='func host start --port 7072 --pause-on-error'

if [ $machine = "linux" ]; then
   setxkbmap -option "caps:escape"
   setxkbmap -option "terminate:ctrl_alt_bksp"
fi

#PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] ' # without git branch
PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;33m\]$(__git_ps1 " [%s]")\[\033[01;32m\]]\$\[\033[00m\] '

# For nvm
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
#[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# For dotnet
export DOTNET_ROOT=$HOME/.config/dotnet
export PATH=$PATH:$HOME/.config/dotnet
# Add .NET Core SDK tools
export PATH="$PATH:$HOME/.dotnet/tools"

# For emscripten/webassembly
#[ -f ~/projects/emsdk/emsdk_env.sh ] && source ~/projects/emsdk/emsdk_env.sh ?> /dev/null

# FZF
#[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# For pipenv
export PATH="$PATH:~/.local/bin"

# For pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# For pycharm
export PATH="$PATH:~/Downloads/pycharm-community-2019.1.3/bin"
