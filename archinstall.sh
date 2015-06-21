#!/bin/bash

# TODO: figure out how to fucking generate a whiptail menu command

# Configure disk partitions
whiptail --msgbox "Use cfdisk to configure your disk partitions" 10 48
cfdisk

# Obtain list of disk partitions
parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}')
whiptail --msgbox "Now the partitions will be formatted" 10 40
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda3
mkswap /dev/sda2
swapon /dev/sda2

# Mount disk partitions
mount /dev/sda3 /mnt
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot

# Install base system
whiptail --msgbox "Base packages for new system will now be installed" 10 40
pacstrap /mnt base base-devel libnewt

# Generate fstab file
genfstab -p /mnt >> /mnt/etc/fstab

# Copy chroot portion of script to new system
cp chroot.sh /mnt/

# Change root into the new system
arch-chroot /mnt ./chroot.sh
