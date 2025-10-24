#!/bin/bash

PLAYBOOK_DIR="$1"
[ "$PLAYBOOK_DIR" = "" ] && echo "need playbook dir as an arg" && exit 1

CONFIG_FILES_DIR="$PLAYBOOK_DIR/config_files"

set -e  # exit on any error

for file in .bashrc .inputrc .xprofile .ideavimrc; do
  [ -L "$HOME/$file" ] && rm "$HOME/$file"
  [ -f "$HOME/$file" ] && mv "$HOME/$file" "$HOME/$file$(date +%Y%m%d)"
  ln -s $CONFIG_FILES_DIR/$file "$HOME/$file"

  [ ! -L "$HOME/$file" ] && echo "symlink not found $HOME/$file" && exit 1
done

[ -L $HOME/.config/Code/User/settings.json ] && rm $HOME/.config/Code/User/settings.json
[ -f $HOME/.config/Code/User/settings.json ] && mv $HOME/.config/Code/User/settings.json $HOME/.config/Code/User/settings$(date +%Y%m%d).json
[ -d $HOME/.config/Code/User ] && ln -s $CONFIG_FILES_DIR/vscode-settings.json $HOME/.config/Code/User/settings.json

# @MarkFix arch specific...
[ -L $HOME/.config/Code\ -\ OSS/User/settings.json ] && rm $HOME/.config/Code\ -\ OSS/User/settings.json
[ -f $HOME/.config/Code\ -\ OSS/User/settings.json ] && mv $HOME/.config/Code\ -\ OSS/User/settings.json $HOME/.config/Code\ -\ OSS/User/settings$(date +%Y%m%d).json
[ -d $HOME/.config/Code\ -\ OSS/User ] && ln -s $CONFIG_FILES_DIR/vscode-settings.json $HOME/.config/Code\ -\ OSS/User/settings.json

[ -L $HOME/.config/nvim ] && rm $HOME/.config/nvim
[ -d $HOME/.config/nvim ] && mv $HOME/.config/nvim $HOME/.config/nvim$(date +%Y%m%d)
ln -s $CONFIG_FILES_DIR/nvim $HOME/.config/nvim
[ ! -L "$HOME/.config/nvim" ] && echo "symlink not found $HOME/.config/nvm" && exit 1

[ -L $HOME/.gitconfig ] && rm $HOME/.gitconfig
[ -f $HOME/.gitconfig ] && [ ! -f $HOME/.gitconfig$(date +%Y%m%d) ] && mv $HOME/.gitconfig $HOME/.gitconfig$(date +%Y%m%d)
[ -f $HOME/.gitconfig ] && rm $HOME/.gitconfig
# we copy later using a template to obscure the email address

# @MarkFix v0.12 has a built in plugin manager...
# nvim --headless -c 'Lazy install' -c 'Lazy update' -c 'quitall'

exit 0
