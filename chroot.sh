#!/usr/bin/bash

# Set hostname
echo $(whiptail --inputbox "Enter a hostname to use for this sytem" 10 50 --title "Set hostname" 3>&1 1>&2 2>&3) > /etc/hostname

# Set timezone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

# Open /etc/locale.gen for user editing
whiptail --msgbox "Uncomment the locale you wish to use in /etc/locale.gen" 10 50
vi /etc/locale.gen

# Generate locale
locale-gen

# Set LANG in /etc/locale.conf(make this an option)
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Create initial RAM disk
mkinitcpio -p linux

# Set root passwd
input1=""
input2=" "

while [[ $input1 != $input2 ]]; do
	input1=$(whiptail --passwordbox "Enter the password for root" 10 50 --title "Set Root Password" 3>&1 1>&2 2>&3)
	input2=$(whiptail --passwordbox "Enter the password again" 10 50 --title "Set Root Password" 3>&1 1>&2 2>&3)
	if [[ $input1 = $input2 ]]; then
		echo "root:$input1" | chpasswd
	else
		echo "The passwords did not match please try again"
	fi
done

# Install bootloader
pacman -S syslinux
syslinux-install_update -i -a -m

# Exit chroot
exit
