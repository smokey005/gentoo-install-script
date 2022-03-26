#!/bin/bash


check_file_exists () {
	file=$1
	if [ -e $file ]; then
		exists=true
	else
		printf "%s doesn't exist\n" $file
		exists=false
		$2
	fi
}
check_dir_exists () {
	file=$1
	if [ -d $file ]; then
		exists=true
	else
		printf "%s doesn't exist\n" $file
		exists=false
		$2
	fi
}

if [ "$EUID" -ne 0 ]
  then printf "The script has to be run as root.\n"
  exit
fi

printf "This script is designed for gentoo linux and it will not work in any other OS\n"
printf "Installing software listed in software.txt...\n"

SOFTWARE="`sed -e 's/#.*$//' -e '/^$/d' software.txt | tr '\n' ' '`"
emaint -a sync

eselect repository enable steam-overlay
emerge --autounmask-continue games-util/steam-launcher games-util/steam-meta
emerge --autounmask-continue -q $SOFTWARE

cd $script_home
cd ..


printf "software installed\n"