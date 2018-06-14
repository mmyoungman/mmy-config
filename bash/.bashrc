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

PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '

# Use nvim, if available
[ -f /usr/bin/nvim ] && alias vim=nvim
[ -f /usr/bin/nvim ] && EDITOR=/usr/bin/nvim

# Tab completion for bash/git
[ -f /usr/share/bash-completion/completions/git ] && source /usr/share/bash-completion/completions/git

if [ $machine = "linux" ] 
then
   # Swap caps lock and escape
   setxkbmap -option "caps:escape"

   alias ls='ls --color=auto'

elif [ $machine = "mac" ] 
then
   alias ls='ls -G'
   alias python=python3
   alias pip=pip3
   export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
   [ -f ~/projects/account-cosmos/run ] && source ~/projects/account-cosmos/run
fi

# Git stuff
alias gs="git status"
alias gd="git diff"
alias gl="git pull"
alias ga="git add"
alias gc="git commit -m"
alias go="git checkout"
