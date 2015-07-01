#!/bin/bash

format_disks(){

	if [[ ! -z $parts ]]; then
		get_partitions;
	fi

	# Generate whiptail menu command for partition formatting
	partmenu="whiptail --menu --noitem \"Pick a partition to format\" 20 50 10"
	for x in $parts; do
			partmenu="$partmenu \"$x\" \"\""
	done
	partmenu="$partmenu \"done\" \"\""

	# Ask user for formatting preferences until done or cancel are selected
	partmenuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	
	while [[ $partmenuchoice != "done" && $partmenuchoice != "" ]]; do
			fs=$(whiptail --menu --noitem "How would you like to format $partmenuchoice?" 20 50 10 "ext2" "" "ext3" "" "ext4" "" "vfat" "" "xfs" "" 3>&1 1>&2 2>&3)
			eval "mkfs.$fs $partmenuchoice"
			partmenuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	done
}


setup_swap(){

	# Generate swap menu command
	swapmenu="whiptail --menu --noitem \"Pick a partition to use as swap\" 20 50 10"
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

	if [[ ! -z $parts ]]; then
		get_partitions;
	fi

	# Generate partition mounting menu
	mountmenu="whiptail --menu --noitem \"Pick a partition to mount\" 20 50 10"
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
		# construct command string for time region
		timemenu="whiptail --menu \"Select a region\" 25 50 15"

		for region in $(ls /usr/share/zoneinfo | xargs); do
			if [[ -d /usr/share/zoneinfo/$region ]]; then
				timemenu="$timemenu \"$region\" \"\""
			fi
		done

		region=$(eval $timemenu 3>&1 1>&2 2>&3)	

		# if user did not cancel construct command string for time zone
		if [[ $region != "" ]]; then
			submenu="whiptail --menu \"Select a timezone\" 25 50 15"
			for zone in $(ls /usr/share/zoneinfo/$region | xargs); do
				submenu="$submenu \"$zone\" \"\""
			done

			zone=$(eval $submenu 3>&1 1>&2 2>&3)

			# if user did not cancel set timezone
			if [[ $zone != "" ]]; then
				# if this is a directory there is a subzone
				if [[ -d /usr/share/zoneinfo/$region/$zone ]]; then
					subzonemenu="whiptail --menu \"Select a subzone\" 25 50 15"
					for subzone in $(ls /usr/share/zoneinfo/$region/$zone/ | xargs); do
						subzonemenu="$subzonemenu \"$subzone\" \"\""
					done
					subzone=$(eval $subzonemenu 3>&1 1>&2 2>&3)
					if [[ $subzone != "" ]]; then
						ln -sf /usr/share/zoneinfo/$region/$zone/$subzone /etc/localtime
					fi
				fi
			else # there is no subzone
				arch-chroot /mnt ln -sf /usr/share/zoneinfo/$region/$zone /etc/localtime
			fi
		fi
}

set_locale(){
		whiptail --msgbox "Uncomment the locale you wish to use in /etc/locale.gen" 15 50
		arch-chroot /mnt vi /etc/locale.gen
		arch-chroot /mnt locale-gen
		arch-chroot /mnt echo $(locale | grep LANG) > /etc/locale.conf
}

set_root_passwd(){
		pass1=""
		pass2=" "
		while [[ $pass1 != $pass2 || $pass1 == "" ]]; do
			pass1=$(whiptail --passwordbox "Enter the password you wish to use for root" 15 50 3>&1 1>&2 2>&3)
			pass2=$(whiptail --passwordbox "Enter the password again" 15 50 3>&1 1>&2 2>&3)

			if [[ $pass1 != $pass2 ]]; then
				whiptail --msgbox "Passwords do not match please try again" 15 50
			elif [[ $pass1 == "" ]]; then
				whiptail --msgbox "Password cannot be blank please try again" 15 50
			else
				echo "echo \"root:$pass1\" | chpasswd" > /mnt/changeroot.sh
				arch-chroot /mnt chmod +x changeroot.sh
				arch-chroot /mnt ./changeroot.sh
				arch-chroot /mnt rm changeroot.sh
			fi

		done
}

add_user(){
		user=$(whiptail --inputbox "Enter a new username" 15 50 3>&1 1>&2 2>&3)
		groups=$(whiptail --inputbox "Enter any secondary groups you would like the new user to be in, seperated by comma" 15 50 3>&1 1>&2 2>&3)

		if [[ $user != "" ]]; then
			if [[ $groups != "" ]]; then
					arch-chroot /mnt useradd -m -G $groups $user
			else
					arch-chroot /mnt useradd -m $user
			fi

			pass1="default1"
			pass2="default2"

			while [[ $pass1 != $pass2 || $pass1 == "" ]]; do
				pass1=$(whiptail --passwordbox "Please enter a password for user $user" 15 50 3>&1 1>&2 2>&3)
				pass2=$(whiptail --passwordbox "Please enter again" 15 50 3>&1 1>&2 2>&3)
				if [[ $pass1 != $pass2 ]]; then
					whiptail --msgbox "Passwords do no match please try again" 15 50
				elif [[ $pass1 == "" ]]; then
					whiptail --msgbox "Password cannot be blank please try again" 15 50
				else
					echo "echo \"$user:$pass1\" | chpasswd" > /mnt/changepass.sh
					arch-chroot /mnt chmod +x changepass.sh
					arch-chroot /mnt ./changepass.sh
					arch-chroot /mnt rm changepass.sh
				fi
			done
			
		fi
}

# TODO: add options for UEFI bootloaders
install_bootloader(){
	bootmenu="whiptail --menu --notags \"Select the bootloader you wish to use\" 15 50 5 \
									\"syslinux\" \"Syslinux\" \
									\"grub\" \"GRUB\" \
	"
	bootchoice=$(eval $bootmenu 3>&1 1>&2 2>&3)

	if [[ $bootchoice != "" ]]; then
		if [[ $bootchoice == "syslinux"]]; then
			arch-chroot /mnt pacman -S syslinux
			arch-chroot /mnt syslinux-install_update -i -a -m
			whiptail --msgbox "Please confirm that the syslinux installation chose the correct root partition"
			nano /boot/syslinux/syslinux.cfg
		elif [[ $bootchoice == "grub" ]]; then
			arch-chroot /mnt pacman -S grub
			diskmenu="whiptail --menu --noitem "Please select the disk on which you want to install GRUB" 15 50 5"

			for disk in $(ls /dev | grep -e "^sd.$" | xargs); do
				diskmenu="$diskmenu \"/dev/$disk\" \"\""
			done

			disk=$(eval $diskmenu 3>&1 1>&2 2>&3)
			if [[ $disk != "" ]]; then
				arch-chroot /mnt grub-install --target=i386-pc --recheck --debug $disk
				grub-mkconfig -o /boot/grub/grub.cfg
			fi
		fi
	fi
}

install_drivers(){
	drivermenu="whiptail --menu --notags \"Select your video driver\" 15 50 6 \
											\"xf86-video-ati\" \"ati\" \
											\"xf86-video-intel\" \"intel\" \
											\"xf86-video-nouveau\" \"nouveau\" \
											\"nvidia\" \"nvidia\" \
											\"nvidia-340xx\" \"nvidia-340xx\" \
											\"nvidia-304xx\" \"nvidia-304xx\" \
	"
	driver=$(eval $drivermenu 3>&1 1>&2 2>&3)
	if [[ $driver != "" ]]; then
		arch-chroot /mnt pacman -S $driver
	fi
}

# TODO: add options for other desktops
install_desktop(){
	arch-chroot /mnt pacman -S xorg-server xorg-server-utils xorg-xinit xorg-twm xorg-xclock xterm
}

get_partitions(){
	# Obtain list of disk partitions
	parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}');
}

# Create string of command for main menu
mainmenu="whiptail --menu --notags \"Arch Install Scripts\" 25 50 15 \
			\"part\" \"Partition Disk(s)\" \
			\"format\" \"Format Partitions\" \
			\"swap\" \"Setup Swap\" \
			\"mount\" \"Mount Paritions\" \
			\"base\" \"Install Base System\" \
			\"hostname\" \"Set Hostname\" \
			\"time\" \"Set Timezone\" \
			\"locale\" \"Set Locale\" \
			\"root\" \"Set Root Password\" \
			\"users\" \"Add User(s)\" \
			\"boot\" \"Install Bootloader\" \
			\"drivers\" \"Install Graphics Drivers\" \
			\"desktop\" \"Install Desktop Environment\" \
			\"done\" \"Finish Install and Exit Script\" \
"

mainmenuchoice="default"

while [[ $mainmenuchoice != "done" && $mainmenuchoice != "" ]]; do
	mainmenuchoice=$(eval $mainmenu 3>&1 1>&2 2>&3)

	case $mainmenuchoice in

	"part")
		cfdisk
		get_partitions;;
	"format")
		format_disks;;
	"swap")
		setup_swap;;
	"mount")
		mount_partitions;;
	"base")
		pacstrap /mnt base sudo
		genfstab -p /mnt >> /mnt/etc/fstab;;
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
	"done")
		arch-chroot /mnt mkinitcpio -p linux;;
	esac
done
