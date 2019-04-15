#!/bin/bash

git clone --separate-git-dir="$HOME"/.dotfiles "$1" ~

# Backup init method
# git clone --separate-git-dir="$HOME"/.dotfiles "$1" tmpdotfiles
# rsync --recursive --verbose --exclude '.git' tmpdotfiles/ "$HOME"/
# rm -r tmpdotfiles

# Configure bare repo
# git config --local status.showUntrackedFiles no
# git config --local user.name "$NAME"
# git config --local user.email "$EMAIL"
