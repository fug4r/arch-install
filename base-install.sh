#!/bin/bash

ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime
hwclock --systohc
sed -i '178s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=de_CH-latin1" >> /etc/vconsole.conf
echo "arch" >> /etc/hostname
echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1       localhost" >> /etc/hosts
echo "127.0.1.1 arch.localdomain arch" >> /etc/hosts
echo root:password | chpasswd

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
