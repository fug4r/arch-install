#!/bin/bash

# General settings

read -p "Enter hostname: " hostname
echo "Config..."

echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "$hostname" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 $hostname.localdomain $hostname" >> /etc/hosts


echo "Root passwd"
echo root:password | chpasswd
echo "Root passwd set"

systemctl enable NetworkManager.service
systemctl enable bluetooth.service
systemctl enable cups.service
systemctl enable ipp-usb.service
systemctl enable sshd.service
systemctl enable avahi-daemon.service
systemctl enable firewalld.service
systemctl enable acpid.service
systemctl enable tlp.service
systemctl enable reflector.timer
systemctl enable fstrim.timer
systemctl enable logrotate.timer
systemctl enable updatedb.timer
