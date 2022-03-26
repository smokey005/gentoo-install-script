
source /etc/profile
cd deploygentoo
scriptdir=$(pwd)
cd ..
sed -i '/^$/d' install_vars
install_vars=install_vars

install_vars_count="$(wc -w /install_vars)"
disk=$(sed '1q;d' install_vars)
username=$(sed '2q;d' install_vars)
hostname=$(sed '4q;d' install_vars)
cpus=$(sed '6q;d' install_vars)
part_3=$(sed '7q;d' install_vars)
part_1=$(sed '8q;d' install_vars)
part_2=$(sed '9q;d' install_vars)
part_4=$(sed '10q;d' install_vars)
nw_interface=$(sed '12q;d' install_vars)
dev_sd=("/dev/$disk")
mount $part_2 /boot
jobs=("-j12")
printf "mounted boot\n"

emerge --sync --quiet
emerge -q app-portage/mirrorselect
emerge -q gentoolkit
printf "searching for fastest servers\n"
mirrorselect -s5 -b10 -D
printf "sync complete\n"

sleep 10

filename=gentootype.txt
line=$(head -n 1 $filename)

printf "preparing to do big emerge\n"
emerge -uvNDq @world
printf "big emerge complete\n"

printf "Europe/Madrid\n" > /etc/timezone
emerge --config --quiet sys-libs/timezone-data
printf "timezone data emerged\n"
#es_ES.UTF-8 UTF-8
printf "es_ES.UTF-8 UTF-8\n" >> /etc/locale.gen
locale-gen
printf "script complete\n"
eselect locale set 4
env-update && source /etc/profile

#Installs the kernel

printf "preparing to emerge kernel sources\n"
emerge -q sys-kernel/gentoo-sources
eselect kernel set 1
ls -l /usr/src/linux/
cd /usr/src/linux/
emerge -q sys-apps/pciutils
emerge -q app-arch/lzop
emerge -q app-arch/zstd
emerge --autounmask-continue -q sys-kernel/genkernel
emerge app-eselect/eselect-repository

emerge -q sys-kernel/gentoo-kernel-bin
    printf "Kernel installed\n"

genkernel --install --kernel-config=/usr/src/linux/.config initramfs


cd /etc/init.d
#enables DHCP
sed -i -e "s/localhost/$hostname/g" /etc/conf.d/hostname
emerge --noreplace --quiet net-misc/netifrc
emerge -q net-misc/networkmanager
rc-update add NetworkManager default
rc-update add elogind boot

lscpu >> install_vars
UUID2=$(blkid -s UUID -o value $part_2)
UUID2=("UUID=${UUID2}")
UUID3=$(blkid -s UUID -o value $part_3)
UUID3=("UUID=${UUID3}")
UUID4=$(blkid -s UUID -o value $part_4)
UUID4=("UUID=${UUID4}")
printf "%s\t\t/boot/efi\tvfat\t\tdefaults\t0 2\n" $UUID2 >> /etc/fstab
SUB_STR='/dev/'
if [[ "$part_3" == *"$SUB_STR"* ]]; then
    printf "%s\t\tnone\t\tswap\t\tsw\t\t0 0\n" $UUID3 >> /etc/fstab
fi
printf "%s\t\t/\t\text4\t\tnoatime\t\t0 1\n" $UUID4 >> /etc/fstab

emerge -q sys-apps/mlocate
emerge -q net-misc/dhcpcd

#installs grub
emerge --verbose -q sys-boot/grub:2
grub-install --target=x86_64-efi --efi-directory=/boot
grub-mkconfig -o /boot/grub/grub.cfg
printf "updated grub\n"
printf "run commands manually from here on to see what breaks\n"
cd ..

stage3=$(ls stage3*)
rm -rf $stage3

while true; do
    printf "enter the password for your root user\n>"
    read -s password
    printf "re-enter the password for your root user\n>"
    read -s password_compare
    if [ "$password" = "$password_compare" ]; then
	echo "root:$password" | chpasswd
        break
    else
        printf ${LIGHTRED}"passwords do not match, re enter them\n"
        printf ${WHITE}".\n"
        sleep 3
        clear
    fi
done
while truer the password for your user %s\n>" $username
    printf "re-enter the password for %s\n>" "$username"
    read -s password_compare
    if [ "$password" = "$password_compare" ]; then
	echo "$username:$password" | chpasswd
        break
    else
        printf ${LIGHTRED}"passwords do not match, re enter them\n"
        printf ${WHITE}".\n"
        sleep 3
        clear
    fi
done
printf "cleaning up\n"
r
rm -rf /install_vars
cp -r /deploygentoo/gentoo/portage/savedcon-r /deploygentoo/gentoo/portage/env /etc/portage/
cp /deploygentoo/gentoo/portage/package.env /etc/portage/
rm -rf /deploygentoo
printf "You now have a completed gentoo installation system, reboot and remove the installation media to load it\nm -rf /post_chroot.sh
