export PS1='\[\033[01;32m\][\u@\h\[\033[01;37m\] \W\[\033[01;32m\]]\$\[\033[00m\] '
export PATH=$PATH:/usr/local/bin
#alias ls='ls -aGFh'

# NOTE: you will need to upgrade bash using homebrew!
set -o vi

# alias for python
#alias python=python2.7
alias python=python3
alias pip=pip3

# Required for automated tests (~/projects/automation)
export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"

# For cosmos completion
source ~/projects/account-cosmos/run
