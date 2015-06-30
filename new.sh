#!/bin/bash

# Obtain list of disk partitions
parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}')
let partcount=$(echo $parts | wc -w)

format_disks(){

	# Generate whiptail menu command for partition formatting
	partmenu="whiptail --menu --noitem \"Pick a partition to format\" 15 50 $partcount"
	for x in $parts; do
			partmenu="$partmenu \"$x\" \"\""
	done
	partmenu="$partmenu \"done\" \"\""

	# Ask user for formatting preferences until done or cancel are selected
	menuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	
	while [[ $menuchoice != "done" ]]; do
			if [[ $menuchoice = "" ]]; then
					echo "Install aborted by user"
					exit 0
			fi
			fs=$(whiptail --menu --noitem "How would you like to format $menuchoice?" 10 50 5 "ext2" "" "ext3" "" "ext4" "" "vfat" "" "xfs" "" 3>&1 1>&2 2>&3)
			eval "mkfs.$fs $menuchoice"
			menuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	done
}

setup_swap(){

	# Generate swap menu command
	swapmenu="whiptail --menu --noitem \"Pick a partition to use as swap\" 15 50 $partcount"
	for x in $parts; do
			swapmenu="$swapmenu \"$x\" \"\""
	done
	swapmenu="$swapmenu \"no swap\" \"\""
	
	# Format swap partition if present
	swapmenuchoice=$(eval $swapmenu 3>&1 1>&2 2>&3)
	if [[ $swapmenuchoice != "done" ]]; then
			if [[ $swapmenuchoice = "" ]]; then
					echo "Install aborted by user"
					exit 0
			fi
			mkswap $swapmenuchoice
			swapon $swapmenuchoice
	fi
}

mount_partitions(){

	# Generate partition mounting menu
	mountmenu="whiptail --menu --noitem \"Pick a partition to mount\" 15 50 $partcount"
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
#set_hostname(){}
#set_timezone(){}
#set_locale(){}
#set_root_passwd(){}
#add_user(){}
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
				cfdisk;;
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
