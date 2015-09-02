#!/bin/bash

format_disks(){

	if [[ -z $parts ]]; then
		get_partitions
		let partcount=$(echo $parts | wc -w)
		let partcount+=1
	fi


	# Generate whiptail menu command for partition formatting
	partmenu="whiptail --menu --noitem \"Pick a partition to format\" 15 40 $partcount"
	for x in $parts; do
			partmenu="$partmenu \"$x\" \"\""
	done
	partmenu="$partmenu \"done\" \"\""

	# Ask user for formatting preferences until done or cancel are selected
	partmenuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	
	while [[ $partmenuchoice != "done" && $partmenuchoice != "" ]]; do
			fs=$(whiptail --menu --noitem "How would you like to format $partmenuchoice?" 13 45 5 "ext2" "" "ext3" "" "ext4" "" "vfat" "" "xfs" "" "btrfs" "" 3>&1 1>&2 2>&3)
			if [[ $fs != "" ]]; then
				eval "mkfs.$fs $partmenuchoice"
			fi
			partmenuchoice=$(eval $partmenu 3>&1 1>&2 2>&3)
	done
}


setup_swap(){

	if [[ -z $parts ]]; then
		get_partitions
		let partcount=$(echo $parts | wc -w)
		let partcount+=1
	fi

	# Generate swap menu command
	swapmenu="whiptail --menu --noitem \"Pick a partition to use as swap\" 15 35 $partcount"
	for x in $parts; do
			swapmenu="$swapmenu \"$x\" \"\""
	done
	swapmenu="$swapmenu \"no swap\" \"\""
	
	# Format swap partition if present
	swapmenuchoice=$(eval $swapmenu 3>&1 1>&2 2>&3)
	if [[ $swapmenuchoice != "done" && $swapmenuchoice != "" ]]; then
			mkswap $swapmenuchoice
			swapon $swapmenuchoice
	fi
}

mount_partitions(){

	if [[ -z $parts ]]; then
		get_partitions
		let partcount=$(echo $parts | wc -w)
		let partcount+=1
	fi

	# Generate partition mounting menu
	mountmenu="whiptail --menu --noitem \"Pick a partition to mount\" 15 40 $partcount"
	for x in $parts; do
			mountmenu="$mountmenu \"$x\" \"\""
	done
	mountmenu="$mountmenu \"done\" \"\""
	
	# Mount disk partitions
	mountmenuchoice=$(eval $mountmenu 3>&1 1>&2 2>&3)
	
	while [[ $mountmenuchoice != "done" && $mountmenuchoice != "" ]]; do
			location=$(whiptail --inputbox "Where would you like to mount $mountmenuchoice?" 10 45 3>&1 1>&2 2>&3)
	
			if [[ $location != "" ]]; then
				if [ ${location:0:4} == "/mnt" ]; then
					if [ ! -d $location]; then
						mkdir $location
					fi
					mount $mountmenuchoice $location
				else
					if [ ! -d "/mnt/$location" ]; then
						mkdir /mnt/$location
					fi
					mount $mountmenuchoice /mnt/$location
				fi
			fi
			mountmenuchoice=$(eval $mountmenu 3>&1 1>&2 2>&3)
	
	done
}

set_hostname(){
		hostname=$(whiptail --inputbox "Please enter a hostname for the new system" 10 46 3>&1 1>&2 2>&3)
		echo $hostname > /mnt/etc/hostname
}

setup_network(){
	dhcp=$(whiptail --yesno "Would you like to use DHCP?" 7 31 3>&1 1>&2 2>&3)
	if [[ $dhcp == "yes" ]]; then
		arch-chroot /mnt systemctl enable dhcpcd
	elif [[ $dhcp == "no" ]]; then
		# TODO: make setup of static ip possible
		sleep 1
	fi
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
		localemenu="whiptail --menu --noitem \"Please select the locale you want to use\" 25 50 15"
		for line in $(seq 24 484); do
				localemenu="$localemenu \"$(head -n $line /mnt/etc/locale.gen | tail -n 1 | sed "s/#//")\" \"\""
		done
		locale=$(eval $localemenu 3>&1 1>&2 2>&3 | cut -d " " -f 1)
		if [[ $locale != "" ]]; then
				# get line number in /etc/locale.gen
				line=$(grep -n $locale /mnt/etc/locale.gen | cut -d : -f 1 | tail -n 1)
				# uncomment said line
				sed -i"" "$line s/#//" /mnt/etc/locale.gen
				arch-chroot /mnt locale-gen
				echo "LANG=$(grep -e "^[^#]" /mnt/etc/locale.gen | awk '{print $1}')" > /mnt/etc/locale.conf
		fi
}

# TODO: fix the cancel logic so that blank entries dont cancel but button presses do
set_root_passwd(){
		pass1=" "
		pass2="  "
		while [[ $pass1 != $pass2  && ! -z $pass1 && ! -z $pass2 ]]; do
			pass1=$(whiptail --passwordbox "Enter the password you wish to use for root" 10 50 3>&1 1>&2 2>&3)
			pass2=$(whiptail --passwordbox "Enter the password again" 10 50 3>&1 1>&2 2>&3)

			if [[ $pass1 != $pass2 && ! -z $pass1 &&  ! -z $pass2 ]]; then
				whiptail --msgbox "Passwords do not match please try again" 10 50
			elif [[ $pass1 == "" && $pass2 == "" ]]; then
				whiptail --msgbox "Password cannot be blank please try again" 10 50
				pass1=" "
				pass2="  "
			elif [[ $pass1 == $pass2 ]]; then
				echo "echo \"root:$pass1\" | chpasswd" > /mnt/changeroot.sh
				arch-chroot /mnt chmod +x changeroot.sh
				arch-chroot /mnt ./changeroot.sh
				arch-chroot /mnt rm changeroot.sh
			fi

		done
}

# TODO: update password flow control to satisfy same problems as set_root_passwd
add_user(){
		user=$(whiptail --inputbox "Enter a new username" 10 50 3>&1 1>&2 2>&3)

		if [[ $user != "" ]]; then
			groups=$(whiptail --inputbox "Enter any secondary groups you would like the new user to be in, seperated by comma" 15 50 3>&1 1>&2 2>&3)
			if [[ $groups != "" ]]; then
					arch-chroot /mnt useradd -m -G $groups $user
			else
					arch-chroot /mnt useradd -m $user
			fi

			pass1="default1"
			pass2="default2"

			while [[ $pass1 != $pass2 || $pass1 == "" ]]; do
				pass1=$(whiptail --passwordbox "Please enter a password for user $user" 10 50 3>&1 1>&2 2>&3)
				pass2=$(whiptail --passwordbox "Please enter again" 10 50 3>&1 1>&2 2>&3)
				if [[ $pass1 != $pass2 ]]; then
					whiptail --msgbox "Passwords do no match please try again" 10 50
				elif [[ $pass1 == "" ]]; then
					whiptail --msgbox "Password cannot be blank please try again" 10 50
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
	bootmenu="whiptail --menu --notags \"Select the bootloader you wish to use\" 10 50 2 \
									\"syslinux\" \"Syslinux\" \
									\"grub\" \"GRUB\" \
	"
	bootchoice=$(eval $bootmenu 3>&1 1>&2 2>&3)

	if [[ $bootchoice != "" ]]; then
		if [[ $bootchoice == "syslinux" ]]; then
			arch-chroot /mnt pacman -S syslinux
			arch-chroot /mnt syslinux-install_update -i -a -m
			whiptail --msgbox "Please confirm that the syslinux installation chose the correct root partition"
			vim /mnt/boot/syslinux/syslinux.cfg
		elif [[ $bootchoice == "grub" ]]; then
			arch-chroot /mnt pacman -S grub

			for disk in $(ls /dev | grep -e "^sd.$" | xargs); do
				diskmenu="$diskmenu \"/dev/$disk\" \"\""
			done

			diskmenu="whiptail --menu --noitem \"Please select the disk on which you want to install GRUB\" 15 50 5"


			disk=$(eval $diskmenu 3>&1 1>&2 2>&3)
			if [[ $disk != "" ]]; then
				arch-chroot /mnt grub-install --target=i386-pc --recheck --debug $disk
				arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
			fi
		fi
	fi
}

install_drivers(){
	drivermenu="whiptail --menu --notags \"Select your video driver\" 15 50 7 \
											\"xf86-video-ati\" \"ati\" \
											\"xf86-video-intel\" \"intel\" \
											\"xf86-video-nouveau\" \"nouveau\" \
											\"nvidia\" \"nvidia\" \
											\"nvidia-340xx\" \"nvidia-340xx\" \
											\"nvidia-304xx\" \"nvidia-304xx\" \
											\"virtualbox-guest-utils\" \"virtualbox\" \
	"
	driver=$(eval $drivermenu 3>&1 1>&2 2>&3)
	if [[ $driver != "" ]]; then
		arch-chroot /mnt pacman -S $driver
	fi
}

install_desktop(){
	demenu="whiptail --menu --notags \"Select the DE you wish to install\" 17 50 9 \
											\"cinnamon\" \"Cinnamon\" \
											\"enlightenment\" \"Enlightenment\" \
											\"gnome\" \"Gnome\" \
											\"kdebase-workspace\" \"KDE 4\" \
											\"plasma\" \"KDE 5 Plasma\" \
											\"lxde\" \"LXDE\" \
											\"lxqt\" \"LXQt\" \
											\"mate\" \"MATE\" \
											\"xfce4\" \"Xfce\" \
	"
	wmmenu="whiptail --menu --notags \"Select the WM you wish to install\" 21 50 13 \
											\"blackbox\" \"Blackbox\" \
											\"fluxbox\" \"Fluxbox\" \
											\"openbox\" \"Openbox\"
											\"fvwm\" \"FVWM\" \
											\"icewm\" \"iceWM\" \
											\"jwm\" \"JWM\" \
											\"windowmaker\" \"Window Maker\" \
											\"bspwm\" \"Bspwm\" \
											\"herbstluftwm\" \"Herbstluftwm\" \
											\"awesome\" \"Awesome\" \
											\"dwm\" \"dwm\" \
											\"i3\" \"i3\" \
											\"xmonad\" \"xmonad\" \
	"
	DEorWM=$(whiptail --menu --notags "Would you like to install a DE or a WM?" 10 43 2 "de" "Desktop Environment" "wm" "Window Manager" 3>&1 1>&2 2>&3)
	if [[ $DEorWM != "" ]]; then
		if [[ $DEorWM == "de" ]]; then
			menuchoice=$(eval $demenu 3>&1 1>&2 2>&3)
		elif [[ $DEorWM == "wm" ]]; then
			menuchoice=$(eval $wmmenu 3>&1 1>&2 2>&3)
		fi
	fi

	if [[ $menuchoice != "" ]]; then
		arch-chroot /mnt pacman -S xorg-server xorg-server-utils xorg-xinit xorg-twm xorg-xclock xterm
		arch-chroot /mnt pacman -S $menuchoice
	fi
}

# TODO: test the alteration of sudoers file
install_helper(){
	whiptail --msgbox "Note: Installation of an AUR helper requires installation of the base-devel package" 15 50
	helpermenu="whiptail --menu --notag \"Select a AUR helper to install\" 15 50 5 \
									\"aura\" \"Aura\" \
									\"autoaur\" \"Autoaur\" \
									\"cower\" \"Cower\" \
									\"packer\" \"Packer\" \
									\"yaourt\" \"Yaourt\" \
	"
	helper=$(eval $helpermenu 3>&1 1>&2 2>&3)
	if [[ $helper != "" ]]; then
		pacstrap /mnt base-devel wget
		mkdir /mnt/home/build
		chown nobody:nobody /mnt/home/build
		chmod g+ws /mnt/home/build
		sudo -u nobody wget -P /mnt/home/build https://aur.archlinux.org/cgit/aur.git/snapshot/"$helper".tar.gz
		cp helper-install.sh /mnt/home/build
		arch-chroot /mnt /mnt/home/build/helper-install.sh $helper
	fi
}

get_partitions(){
	# Obtain list of disk partitions
	parts=$(fdisk -l | grep -e "^/dev/" | awk '{print $1}');
}

# Create string of command for main menu
mainmenu="whiptail --menu --notags \"Arch Install Scripts\" 25 50 16 \
			\"part\" \"Partition Disk(s)\" \
			\"format\" \"Format Partitions\" \
			\"swap\" \"Setup Swap\" \
			\"mount\" \"Mount Paritions\" \
			\"base\" \"Install Base System\" \
			\"hostname\" \"Set Hostname\" \
			\"network\" \"Setup Networking\"
			\"time\" \"Set Timezone\" \
			\"locale\" \"Set Locale\" \
			\"root\" \"Set Root Password\" \
			\"users\" \"Add User(s)\" \
			\"boot\" \"Install Bootloader\" \
			\"drivers\" \"Install Graphics Drivers\" \
			\"desktop\" \"Install Desktop Environment\" \
			\"helper\" \"Install AUR Helper\"
			\"done\" \"Make Initial RAM Image and Exit Script\" \
"

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
		pacstrap /mnt base sudo
		genfstab -p /mnt >> /mnt/etc/fstab;;
	"hostname")
		set_hostname;;
	"network")
		setup_network;;
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
	"helper")
		install_helper;;
	"done")
		arch-chroot /mnt mkinitcpio -p linux;;
	esac
done
