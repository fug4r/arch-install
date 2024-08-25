#!/bin/bash


# Installing packages
echo "Installing packages..."
pacman -S --needed $(grep -v '^#' packages.txt)


# General settings
echo -e "\nConfiguring localtime..."
read -p "Enter timezone region: " region
read -p "Enter timezone city: " city
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc
echo "Localtime configured."

echo -e "\nConfiguring ntp..."
cp ./timesyncd.conf /etc/systemd/timesyncd.conf
echo "Ntp configured."

echo -e "\nConfiguring locale and hostname..."
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf

read -p "Enter hostname: " hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts
echo "Locale and hostname configured."


# Keymap
echo -e "\nSetting console keymap and font..."
cp us-caps2ctrl.map /usr/share/kbd/keymaps
echo "KEYMAP=us-caps2ctrl" >> /etc/vconsole.conf
echo "FONT=ter-124b" >> /etc/vconsole.conf
echo "Keymap and font set."


# PC Speaker
echo -e "\nDisabling PC Speaker..."
rmmod pcspkr
rmmod snd_pcsp
echo "blacklist pcspkr" >> /etc/modprobe.d/nobeep.conf
echo "blacklist snd_pcsp" >> /etc/modprobe.d/nobeep.conf
echo "Disabled PC Speaker..."


# Initramfs & custom edid binary
echo -e "\nConfiguring and generating initramfs..."
mkdir -p /usr/lib/firmware/edid/ && cp ./edid.bin /usr/lib/firmware/edid/
mkinitcpio -p linux
echo "Initramfs set up."


# Installing grub
echo -e "\nInstalling grub..."
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB

echo -e "\nSetting up grub config file..."
echo "Assuming cryptdevice is /dev/mapper/arch-brfs and getting its UUID"
cryptuuid=`blkid | grep arch-btrfs | cut -d'"' -f 2` 
echo "UUID got: $cryptuuid"

echo "Incorporating UUID in grub config file..."
# Copying from default config to prevent its modification
cp ./grub.default ./grub
sed -i -e "s/<>/$cryptuuid/g" grub
echo "Grub settings finished."

echo -e "\nMoving final grub file to /etc/default/grub and making grub config..."
mv ./grub /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg
echo "Grub setup finished."


# Adding admin user and setting root password
echo -e "\nCreating admin user..."
read -p "Enter username: " username

useradd -mG wheel $username
echo -e "Changing $username password..."
passwd $username
sed -i 's/# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/g' /etc/sudoers
echo "Created user $username and configured sudoers file."

echo -e "\nChanging root password..."
passwd root
echo "Root password changed."


# Enabling systemd services
echo -e "\nEnabling various systemd services..."
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
echo "Relevant systemd services enabled."


# Fishing message
printf "\n\e[1;32mDone! \e[0m\n"
