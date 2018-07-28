#
# ~/.bashrc
#

# Update config files
if [ -d ~/projects/mmy-config/ ]
then
   cd ~/projects/mmy-config/
   gitOutput=$(git pull)
   if [ "$gitOutput" != "Already up to date." ] && [ "$gitOutput" != "Already up-to-date." ]
   then
      nvim -c ":PlugClean|:PlugInstall|:qa"
      printf "mmy-config updated\n"
   else
      printf ""
   fi
   cd ~
fi

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
GIT_DIR=~/.config/git/
if [ ! -d $GIT_DIR ];
then
    mkdir -p ~/.config/git/
fi

GIT_PROMPT=~/.config/git/git-prompt.sh
if [ ! -f $GIT_PROMPT ];
then
    mkdir -p ~/.config/git/
    curl -o $GIT_PROMPT 'https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh'
fi
source $GIT_PROMPT

GIT_COMPLETION=~/.config/git/git-completion.bash
if [ ! -f $GIT_COMPLETION ];
then
    #curl -o $GIT_COMPLETION 'https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash'
    curl -o $GIT_COMPLETION 'https://raw.githubusercontent.com/git/git/v2.17.1/contrib/completion/git-completion.bash'
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

# OS specific
if [ $machine = "linux" ] 
then
   # Make caps lock = escape
   setxkbmap -option "caps:escape"
   setxkbmap -option "terminate:ctrl_alt_bksp"

   alias ls='ls --color=auto'

elif [ $machine = "mac" ] 
then
   alias ls='ls -G'
   alias python=python3
   alias pip=pip3
   export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
   [ -f ~/projects/account-cosmos/run ] && source ~/projects/account-cosmos/run
fi

#PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W \[\e[01;33m\]$(__git_ps1 "[%s]")\[\033[01;32m\]]\$\[\033[00m\] '

