#!/bin/bash

# Configure disk partitions
whiptail --msgbox "Use cfdisk to configure your disk partitions" 10 48
cfdisk

# Obtain list of disk partitions
parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}')
let partcount=$(echo $parts | wc -w)
let partcount=$partcount+1

# Generate whiptail menu for partition formatting
menucommand="whiptail --menu --noitem \"Pick a partition to format\" 15 50 $partcount"
for x in $parts; do
	menucommand="$menucommand \"$x\" \"\""
done
menucommand="$menucommand \"done\" \"\""

# Ask user for formatting preferences until done is selected
menuchoice=$(eval $menucommand 3>&1 1>&2 2>&3)

while [[ $menuchoice != "done" ]]; do
	fs=$(whiptail --menu --noitem "How would you like to format $menuchoice?" 10 50 5 "ext2" "" "ext3" "" "ext4" "" "vfat" "" "xfs" "" 3>&1 1>&2 2>&3)
	eval "mkfs.$fs $menuchoice"
	menuchoice=$(eval $menucommand 3>&1 1>&2 2>&3)
done

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
