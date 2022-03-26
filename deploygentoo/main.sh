#!/bin/bash
#Gentoo-Install-Script by Ayoub

cd ..
start_dir=$(pwd)
fdisk -l >> devices
ifconfig -s >> nw_devices
cut -d ' ' -f1 nw_devices >> network_devices
rm -rf nw_devices
sed -e "s/lo//g" -i network_devices
sed -e "s/Iface//g" -i network_devices
sed '/^$/d' network_devices
sed -e '\#Disk /dev/ram#,+5d' -i devices
sed -e '\#Disk /dev/loop#,+5d' -i devices

cat devices
while true; do
    printf "Enter the device name you want to install gentoo on (ex, sda for /dev/sda)\n>"
    read disk
    disk="${disk,,}"
    partition_count="$(grep -o $disk devices | wc -l)"
    disk_chk=("/dev/${disk}")
    if grep "$disk_chk" devices; then
            wipefs -a $disk_chk
            parted -a optimal $disk_chk --script mklabel gpt
            parted $disk_chk --script mkpart primary 1MiB 3MiB
            parted $disk_chk --script name 1 grub
            parted $disk_chk --script set 1 bios_grub on
            parted $disk_chk --script mkpart primary 3MiB 131MiB
            parted $disk_chk --script name 2 boot
            parted $disk_chk --script mkpart primary 131MiB 4227MiB
            parted $disk_chk --script name 3 swap
            parted $disk_chk --script -- mkpart primary 4227MiB -1
            parted $disk_chk --script name 4 rootfs
            parted $disk_chk --script set 2 boot on
            part_1=("${disk_chk}1")
            part_2=("${disk_chk}2")
            part_3=("${disk_chk}3")
            part_4=("${disk_chk}4")
            mkfs.fat -F 32 $part_2
            #mkfs.ext4 $part_2
            mkfs.ext4 $part_4
            mkswap $part_3
            swapon $part_3
            rm -rf devices
            clear
            sleep 2
            break               
    else
        printf "%s is an invalid device, try again with a correct one\n" $disk_chk
        printf ".\n"
        sleep 5
        clear
        cat devices
    fi
done



printf "Enter the username for your NON ROOT user\n>"
read username
username="${username,,}"
printf "Enter the Hostname you want to use\n>"
read hostname
printf "Beginning installation, this will take several minutes\n"


#copying files into place
mount $part_4 /mnt/gentoo
mv deploygentoo /mnt/gentoo
mv network_devices /mnt/gentoo/deploygentoo/
cd /mnt/gentoo/deploygentoo

install_vars=/mnt/gentoo/
cpus=$(grep -c ^processor /proc/cpuinfo)
echo "$disk" >> "$install_vars"
echo "$username" >> "$install_vars"
echo "$hostname" >> "$install_vars"
echo "$cpus" >> "$install_vars"
echo "$part_3" >> "$install_vars"
echo "$part_1" >> "$install_vars"
echo "$part_2" >> "$install_vars"
echo "$part_4" >> "$install_vars"
cat network_devices >> "$install_vars"
rm -f network_devices



STAGE3_PATH_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/latest-stage3-amd64-desktop-openrc.txt
STAGE3_PATH=$(curl -s $STAGE3_PATH_URL | grep -v "^#" | cut -d" " -f1)
STAGE3_URL=http://distfiles.gentoo.org/releases/amd64/autobuilds/$STAGE3_PATH
touch /mnt/gentoo/gentootype.txt
echo latest-stage3-amd64-desktop-openrc >> /mnt/gentoo/gentootype.txt
cd /mnt/gentoo/
while [ 1 ]; do
	wget --retry-connrefused --waitretry=1 --read-timeout=20 --timeout=15 -t 0 $STAGE3_URL
	if [ $? = 0 ]; then break; fi;
	sleep 1s;
done;
check_file_exists () {
	file=$1
	if [ -e $file ]; then
		exists=true
	else
		printf "%s doesn't exist\n" $file
		wget --tries=20 $STAGE3_URL
		exists=false
		$2
	fi
}




check_file_exists /mnt/gentoo/stage3*
stage3=$(ls /mnt/gentoo/stage3*)
tar xpvf $stage3 --xattrs-include='*.*' --numeric-owner
printf "unpacked stage 3\n"

cd /mnt/gentoo/deploygentoo/gentoo/
cp -a /mnt/gentoo/deploygentoo/gentoo/portage/package.use/. /mnt/gentoo/etc/portage/package.use/
cd /mnt/gentoo/
rm -rf /mnt/gentoo/etc/portage/make.conf
cp /mnt/gentoo/deploygentoo/gentoo/portage/make.conf /mnt/gentoo/etc/portage/
printf "copied new make.conf to /etc/portage/\n"
printf "there are %s cpus\n" $cpus
sed -i "s/MAKEOPTS=\"-j12\"/MAKEOPTS=\"-j12 -l12\"/g" /mnt/gentoo/etc/portage/make.conf
sed -i "s/--jobs=12  --load-average=12/--jobs=12  --load-average=12/g" /mnt/gentoo/etc/portage/make.conf
printf "moved portage files into place\n"

cp /mnt/gentoo/deploygentoo/gentoo/portage/package.license /mnt/gentoo/etc/portage
cp /mnt/gentoo/deploygentoo/gentoo/portage/package.accept_keywords /mnt/gentoo/etc/portage/


mkdir --parents /mnt/gentoo/etc/portage/repos.conf
cp /mnt/gentoo/usr/share/portage/config/repos.conf /mnt/gentoo/etc/portage/repos.conf/gentoo.conf
printf "copied gentoo repository to repos.conf\n"
#
##copy DNS info
cp --dereference /etc/resolv.conf /mnt/gentoo/etc
printf "copied over DNS info\n"


cp /mnt/gentoo/deploygentoo/install_vars /mnt/gentoo/



mount --types proc /proc /mnt/gentoo/proc
mount --rbind /sys /mnt/gentoo/sys
mount --make-rslave /mnt/gentoo/sys
mount --rbind /dev /mnt/gentoo/dev
mount --make-rslave /mnt/gentoo/dev
mount --bind /run /mnt/gentoo/run

cd /mnt/gentoo/
chroot /mnt/gentoo 


