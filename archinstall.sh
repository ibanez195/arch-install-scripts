#!/bin/bash

# Configure disk partitions
whiptail --msgbox "Use cfdisk to configure your disk partitions" 10 48
cfdisk

# Obtain list of disk partitions
parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}')
let partcount=$(echo $parts | wc -w)
let partcount=$partcount+1

# Generate whiptail menu for partition formatting
partmenu="whiptail --menu --noitem \"Pick a partition to format\" 15 50 $partcount"
for x in $parts; do
	partmenu="$partmenu \"$x\" \"\""
done
partmenu="$partmenu \"done\" \"\""

# Ask user for formatting preferences until done is selected
menuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)

while [[ $menuchoice != "done" ]]; do
	fs=$(whiptail --menu --noitem "How would you like to format $menuchoice?" 10 50 5 "ext2" "" "ext3" "" "ext4" "" "vfat" "" "xfs" "" 3>&1 1>&2 2>&3)
	eval "mkfs.$fs $menuchoice"
	menuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
done

# Format swap partition if present
swapmenu="whiptail --menu --noitem \"Pick a partition to use as swap\" 15 50 $partcount"
for x in $parts; do
	swapmenu="$swapmenu \"$x\" \"\""
done
swapmenu="$swapmenu \"no swap\" \"\""

swapmenuchoice=$(eval $swapmenu 3>&1 1>&2 2>&3)
if [[ $swapmenuchoice != "done" ]]; then
	mkswap $swapmenuchoice
	swapon $swapmenuchoice
fi

# Mount disk partitions
mountmenu="whiptail --menu --noitem \"Pick a partition to mount\" 15 50 $partcount"
for x in $parts; do
	mountmenu="$mountmenu \"$x\" \"\""
done
mountmenu="$mountmenu \"done\" \"\""

mountmenuchoice=$(eval $mountmenu 3>&1 1>&2 2>&3)

while [[ $mountmenuchoice != "done" ]]; do
	location=$(whiptail --inputbox "Where would you like to mount $mountmenuchoice?" 10 50 3>&1 1>&2 2>&3)
	if [ ! -d "/mnt/$location" ]; then
		mkdir /mnt/$location
	fi
	mount $mountmenuchoice /mnt/$location
	mountmenuchoice=$(eval $mountmenu 3>&1 1>&2 2>&3)
done

# Install base system
whiptail --msgbox "Base packages for new system will now be installed" 10 40
pacstrap /mnt base base-devel libnewt

# Generate fstab file
genfstab -p /mnt >> /mnt/etc/fstab

# Copy chroot portion of script to new system
cp chroot.sh /mnt/

# Change root into the new system
arch-chroot /mnt ./chroot.sh
