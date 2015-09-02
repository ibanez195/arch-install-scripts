#!/bin/bash

sudo -u nobody tar xzf "$1".tar.gz
cd $1
sudo -u nobody makepkg -s --noconfirm
sudo -u nobody pacman -U *.tar.xz
