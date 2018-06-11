#
# ~/.bashrc
#

unameOut="$(uname -s)"
case $unameOut in
   Linux*) machine="linux";;
   Darwin*) machine="mac";;
   *)
      echo ".bashrc says: Unsupported OS detected!"
      ;;
esac

PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '

# Set bash to vi mode
#set -o vi

# In cmd mode, press "v" to open editor
alias vim=nvim
[ -f /usr/bin/nvim ] && EDITOR=/usr/bin/nvim

# Tab completion for bash/git
[ -f /usr/share/bash-completion/completions/git ] && source /usr/share/bash-completion/completions/git

if [ $machine = "linux" ] 
then
   alias ls='ls --color=auto'

   # Swap caps lock and escape
   setxkbmap -option "caps:escape"

elif [ $machine = "mac" ] 
then
   alias ls='ls -G'
   alias python=python3
   alias pip=pip3
   export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"
   [ -f ~/projects/account-cosmos/run ] && source ~/projects/account-cosmos/run
fi
