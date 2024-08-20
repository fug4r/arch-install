#!/bin/bash

# Installing packages
pacman -S --needed $(grep -v '^#' packages.txt)


# General settings
echo "Configuring localtime..."
read -p "Enter timezone region: " region
read -p "Enter timezone city: " city
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc

echo -e "\nConfiguring ntp..."
cp ./timesyncd.conf /etc/systemd/timesyncd.conf

echo -e "\nConfiguring locale and hostname..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

read -p "Enter hostname: " hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo ""


# Ramdisk & custom edid binary
mkdir -p /usr/lib/firmware/edid/ && cp ./edid.bin /usr/lib/firmware/edid/
mkinitcpio -p linux


# Installing grub
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

echo -e "\nAssuming cryptdevice is /dev/mapper/arch-brfs and getting its UUID"
cryptuuid=`blkid | grep arch-btrfs | cut -d'"' -f 2` 
echo "UUID got: $cryptuuid"

echo "Incorporating UUID in grub config file"
# Copying from default config to prevent its modification
cp ./grub.default ./grub
sed -i -e "s/<>/$cryptuuid/g" grub

echo -e "\nCopying final grub file to /etc/default/grub and making grub config"
mv ./grub /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg


# Adding admin user and setting root password
echo -e "\nCreating default admin user..."
read -p "Enter username: " username

useradd -mG wheel $username
echo "\nChanging $username password..."
echo $username:password | chpassword
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers

echo -e "\nChanging root password..."
echo root:password | chpasswd


# Enabling systemd services
systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable cups.service
systemctl enable ipp-usb.service
systemctl enable sshd.service
systemctl enable avahi-daemon.service
systemctl enable firewalld.service
systemctl enable acpid.service
systemctl enable systemd-timesyncd.service
systemctl enable tlp.service
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable logrotate.timer
systemctl enable updatedb.timer


# Fishing message
printf "\n\e[1;32mDone! \e[0m\n"
