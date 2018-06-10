#!/bin/bash

[ -f ~/.bashrc ] && mv ~/.bashrc ~/.bashrc$(date +%Y%m%d)bak
ln -s $(pwd)/.bashrc ~/.bashrc

[ -f ~/.inputrc ] && mv ~/.inputrc ~/.inputrc$(date +%Y%m%d)bak
ln -s $(pwd)/.inputrc ~/.inputrc

[ -d ~/.config/nvim/ ] && mv ~/.config/nvim ~/.config/nvim$(date +%Y%m%d)bak
ln -s $(pwd)/.config/nvim ~/.config/nvim
