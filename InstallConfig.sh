#!/bin/bash

[ -L ~/.bashrc ] && rm ~/.bashrc
[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc$(date +%Y%m%d)
ln -s $(pwd)/bash/.bashrc ~/.bashrc

[ -L ~/.inputrc ] && rm ~/.inputrc
[ -f ~/.inputrc ] && mv ~/.inputrc ~/.inputrc$(date +%Y%m%d)
ln -s $(pwd)/bash/.inputrc ~/.inputrc

[ -L ~/.xprofile ] && rm ~/.xprofile
[ -f ~/.xprofile ] && mv ~/.xprofile ~/.xprofile$(date +%Y%m%d)
ln -s $(pwd)/bash/.xprofile ~/.xprofile

[ -L ~/.config/nvim ] && rm ~/.config/nvim
[ -d ~/.config/nvim/ ] && mv ~/.config/nvim ~/.config/nvim$(date +%Y%m%d)
ln -s $(pwd)/nvim ~/.config/nvim

nvim -c ":PlugClean|:PlugInstall|:qa"

[ -L ~/.ideavimrc ] && rm ~/.ideavimrc
[ -f ~/.ideavimrc ] && mv ~/.ideavimrc ~/.ideavimrc$(date +%Y%m%d)
ln -s $(pwd)/intellij/.ideavimrc ~/.ideavimrc

# And for root?
#[ -L /root/.bashrc ] && rm /root/.bashrc
#[ -f /root/.bashrc ] && mv /root/.bashrc /root/.bashrc$(date +%Y%m%d)
#ln -s $(pwd)/bash/.bashrc /root/.bashrc
#
#[ -L /root/.inputrc ] && rm /root/.inputrc
#[ -f /root/.inputrc ] && mv /root/.inputrc /root/.inputrc$(date +%Y%m%d)
#ln -s $(pwd)/bash/.inputrc /root/.inputrc
#
# This incorrectly creates a symlink to nvim in the $(pwd)/nvim folder!
#[ -L /root/.config/nvim ] && rm /root/.config/nvim
#[ -d /root/.config/nvim/ ] && mv /root/.config/nvim /root/.config/nvim$(date +%Y%m%d)
#ln -s $(pwd)/nvim /root/.config/nvim
