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

[ -L ~/.config/Code/User/settings.json ] && rm ~/.config/Code/User/settings.json
[ -f ~/.config/Code/User/settings.json ] && rm ~/.config/Code/User/settings$(date +%Y%m%d).json
ln -s $(pwd)/vscode/settings.json ~/.config/Code/User/settings.json

[ -L ~/.ideavimrc ] && rm ~/.ideavimrc
[ -f ~/.ideavimrc ] && mv ~/.ideavimrc ~/.ideavimrc$(date +%Y%m%d)
ln -s $(pwd)/intellij/.ideavimrc ~/.ideavimrc
