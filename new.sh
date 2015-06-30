#!/bin/bash

format_disks(){
	# Obtain list of disk partitions
	parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}')
	let partcount=$(echo $parts | wc -w)

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

#setup_swap(){}
#mount_partitions(){}
#install_base(){}
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
				install_base;;
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
