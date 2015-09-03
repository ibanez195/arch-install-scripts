#!/bin/bash

sed -i "85s/#//g" /etc/sudoers
usermod -G wheel nobody
sudo -u nobody tar xzf "$1".tar.gz
cd $1
sudo -u nobody makepkg -s --noconfirm
pacman -U *.tar.xz
sed -i "85s/^/#/g" /etc/sudoers
