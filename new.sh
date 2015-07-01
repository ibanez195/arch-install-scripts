#!/bin/bash

format_disks(){

	# Generate whiptail menu command for partition formatting
	partmenu="whiptail --menu --noitem \"Pick a partition to format\" 20 50 $partcount"
	for x in $parts; do
			partmenu="$partmenu \"$x\" \"\""
	done
	partmenu="$partmenu \"done\" \"\""

	# Ask user for formatting preferences until done or cancel are selected
	partmenuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	
	while [[ $partmenuchoice != "done" && $partmenuchoice != "" ]]; do
			fs=$(whiptail --menu --noitem "How would you like to format $partmenuchoice?" 10 50 5 "ext2" "" "ext3" "" "ext4" "" "vfat" "" "xfs" "" 3>&1 1>&2 2>&3)
			eval "mkfs.$fs $partmenuchoice"
			partmenuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	done
}


setup_swap(){

	# Generate swap menu command
	swapmenu="whiptail --menu --noitem \"Pick a partition to use as swap\" 20 50 $partcount"
	for x in $parts; do
			swapmenu="$swapmenu \"$x\" \"\""
	done
	swapmenu="$swapmenu \"no swap\" \"\""
	
	# Format swap partition if present
	swapmenuchoice=$(eval $swapmenu 3>&1 1>&2 2>&3)
	if [[ $swapmenuchoice != "done" && $swapmenuchoie != "" ]]; then
			mkswap $swapmenuchoice
			swapon $swapmenuchoice
	fi
}

mount_partitions(){

	# Generate partition mounting menu
	mountmenu="whiptail --menu --noitem \"Pick a partition to mount\" 20 50 $partcount"
	for x in $parts; do
			mountmenu="$mountmenu \"$x\" \"\""
	done
	mountmenu="$mountmenu \"done\" \"\""
	
	# Mount disk partitions
	mountmenuchoice=$(eval $mountmenu 3>&1 1>&2 2>&3)
	
	while [[ $mountmenuchoice != "done" ]]; do
			if [[ $mountmenuchoice = "" ]]; then
					echo "Install aborted by user"
					exit 0
			fi
	
			location=$(whiptail --inputbox "Where would you like to mount $mountmenuchoice?" 10 50 3>&1 1>&2 2>&3)
	
			if [[ $location = "" ]]; then
					echo "Install aborted by user"
					exit 0
			fi
	
			if [ ! -d "/mnt/$location" ]; then
					mkdir /mnt/$location
			fi
			mount $mountmenuchoice /mnt/$location
			mountmenuchoice=$(eval $mountmenu 3>&1 1>&2 2>&3)
	done
}

set_hostname(){
		hostname=$(whiptail --inputbox "Please enter a hostname for the new system" 10 50 3>&1 1>&2 2>&3)
		echo $hostname > /mnt/etc/hostname
}

set_timezone(){
		whiptail --msgbox "Setting timezone to America/New_York"
		arch-chroot /mnt ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
}

set_locale(){
		whiptail --msgbox "Uncomment the locale you wish to use in /etc/locale.gen" 15 50
		arch-chroot /mnt vi /etc/locale.gen
}

set_root_passwd(){
		pass1=""
		pass2=" "
		while [[ $pass1 != $pass2 || $pass1 = "" ]]; do
			pass1=$(whiptail --passwordbox "Enter the password you wish to use for root" 15 50 3>&1 1>&2 2>&3)
			pass2=$(whiptail --passwordbox "Enter the password again" 15 50 3>&1 1>&2 2>&3)

			if [[ $pass1 != $pass2 ]]; then
				whiptail --msgbox "Passwords do not match please try again" 15 50
			fi

			if [[ $pass1 == "" ]]; then
				whiptail --msgbox "Password cannot be blank please try again" 15 50
			fi

		done
}

add_user(){
		user=$(whiptail --inputbox "Enter a new username" 15 50 3>&1 1>&2 2>&3)
		groups=$(whiptail --inputbox "Enter any secondary groups you would like the new user to be in" 3>&1 1>&2 2>&3)

		if [[ $groups != "" ]]; then
				arch-chroot /mnt useradd -m -G $groups $user
		else
				arch-chroot /mnt useradd -m $user
		fi
}

#install_bootloader(){}
#install_drivers(){}
#install_desktop(){}

#TODO: clean up main menu command definition

# Create string of command for main menu
mainmenu="whiptail --menu --notags \"Arch Install Scripts\" 25 50 15"
mainmenu="$mainmenu \"part\" \"Partition Disk(s)\""
mainmenu="$mainmenu \"format\" \"Format Partitions\""
mainmenu="$mainmenu \"swap\" \"Setup Swap\""
mainmenu="$mainmenu \"mount\" \"Mount Paritions\""
mainmenu="$mainmenu \"base\" \"Install Base System\""
mainmenu="$mainmenu \"hostname\" \"Set Hostname\""
mainmenu="$mainmenu \"time\" \"Set Timezone\""
mainmenu="$mainmenu \"locale\" \"Set Locale\""
mainmenu="$mainmenu \"root\" \"Set Root Password\""
mainmenu="$mainmenu \"users\" \"Add User(s)\""
mainmenu="$mainmenu \"boot\" \"Install Bootloader\""
mainmenu="$mainmenu \"drivers\" \"Install Graphics Drivers\""
mainmenu="$mainmenu \"desktop\" \"Install Desktop Environment\""
mainmenu="$mainmenu \"done\" \"Finish Install and Exit Script\""

mainmenuchoice="default"

while [[ $mainmenuchoice != "done" && $mainmenuchoice != "" ]]; do
		mainmenuchoice=$(eval $mainmenu 3>&1 1>&2 2>&3)
		
		case $mainmenuchoice in

		"part")
				cfdisk
				
				# Obtain list of disk partitions
				parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}')
				let partcount=$(echo $parts | wc -w)
				let partcount=$partcount+1;;

		"format")
				format_disks;;
		"swap")
				setup_swap;;
		"mount")
				mount_partitions;;
		"base")
				pacstrap /mnt base libnewt sudo;;
		"hostname")
				set_hostname;;
		"time")
				set_timezone;;
		"locale")
				set_locale;;
		"root")
				set_root_passwd;;
		"users")
				add_user;;
		"boot")
				install_bootloader;;
		"drivers")
				install_drivers;;
		"desktop")
				install_desktop;;
		esac
done
