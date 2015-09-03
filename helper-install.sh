#!/bin/bash

pacman -S base-devel wget
chown nobody:nobody /home/build
chmod g+ws /home/build
cd /home/build
sed -i "85s/#//g" /etc/sudoers
usermod -G wheel nobody
sudo -u nobody wget https://aur.archlinux.org/cgit/aur.git/snapshot/"$1".tar.gz
sudo -u nobody tar xzf "$1".tar.gz
cd $1
sudo -u nobody makepkg -s --noconfirm
pacman -U *.tar.xz
sed -i "85s/^/#/g" /etc/sudoers
