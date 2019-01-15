#
# ~/.bashrc
#

# Update config files
#if [ -d ~/projects/mmy-config/ ]
#then
#   cd ~/projects/mmy-config/
#   gitOutput=$(git pull)
#   if [ "$gitOutput" != "Already up to date." ] && [ "$gitOutput" != "Already up-to-date." ]
#   then
#      nvim -c ":PlugClean|:PlugInstall|:qa"
#      printf "mmy-config updated\n"
#   else
#      printf ""
#   fi
#   cd ~
#fi

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
    #curl -o $GIT_COMPLETION 'https://raw.githubusercontent.com/git/git/v2.17.1/contrib/completion/git-completion.bash' # because need git v2.18 for git --list-cmds=
fi
source $GIT_COMPLETION

# Git aliases
alias gs="git status"
__git_complete gs _git_status
alias gd="git diff"
__git_complete gd _git_diff
alias gl="git pull"
__git_complete gl _git_pull
alias ga="git add"
__git_complete ga _git_add
alias gc="git commit"
__git_complete gc _git_commit
alias go="git checkout"
__git_complete go _git_checkout

alias ls='ls --color=auto'
alias ll='ls -l --color=auto'
alias sdn='shutdown now'

if [ $machine = "linux" ]; then
   setxkbmap -option "caps:escape"
   setxkbmap -option "terminate:ctrl_alt_bksp"
fi

#PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] ' # without git branch
PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;33m\]$(__git_ps1 " [%s]")\[\033[01;32m\]]\$\[\033[00m\] '

# For nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# For dotnet
export DOTNET_ROOT=$HOME/.config/dotnet 
export PATH=$PATH:$HOME/.config/dotnet

# For emscripten/webassembly
#[ -f ~/projects/emsdk/emsdk_env.sh ] && source ~/projects/emsdk/emsdk_env.sh ?> /dev/null

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# For pipenv
export PATH="$PATH:~/.local/bin"
