#!/bin/bash

[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc$(date +%Y%m%d)
ln -s $(pwd)/bash/.bashrc ~/.bashrc

[ -f ~/.inputrc ] && mv ~/.inputrc ~/.inputrc$(date +%Y%m%d)
ln -s $(pwd)/bash/.inputrc ~/.inputrc

[ -d ~/.config/nvim/ ] && mv ~/.config/nvim ~/.config/nvim$(date +%Y%m%d)
ln -s $(pwd)/nvim ~/.config/nvim

nvim -c ":PlugInstall|:qa"
