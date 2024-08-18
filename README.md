# Disk encryption on Arch Linux with LVM,LUKS,BTRFS and SWAP Hibernate

Warning! this for amd cpu and nvidia gpu, if your hardware is differenct you will have to install different drivers. Also do not install both amd and intel microcode at the same time.

Encryption without /boot

```
NAME             MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
nvme1n1          259:0    0 476.9G  0 disk  
├─nvme1n1p1      259:1    0   512M  0 part  /boot
└─nvme1n1p2      259:2    0 476.4G  0 part  
  └─cryptlvm     254:0    0 476.4G  0 crypt 
    ├─arch-swap  254:1    0    20G  0 lvm   [SWAP]
    └─arch-btrfs 254:2    0 452.9G  0 lvm   /var/tmp
                                            /home
                                            /var/cache
                                            /var/log
                                            /.snapshots
                                            /
```

Recommended /boot size: 1G
Recommended swap size (source [RHEL wiki](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/storage_administration_guide/ch-swapspace#ch-swapspace)):

```
Amount of RAM    Recommended swap space       Recommended swap space 
in the system                                 if allowing for hibernation
--------------   --------------------------   ---------------------------
⩽ 2 GB           2 times the amount of RAM    3 times the amount of RAM
> 2 GB – 8 GB    Equal to the amount of RAM   2 times the amount of RAM
> 8 GB – 64 GB   At least 4 GB                1.5 times the amount of RAM
> 64 GB          At least 4 GB                Hibernation not recommended
```

## Commands to set up partition
Start disk utility with new GPT
```
gdisk /dev/nvme0n1
o
```
EFI Parition
```
y
n
↵
↵
+1G
ef00
```
LUKS Partition
```
n
↵
↵
↵
8309
```
Write and quit gdisk
```
w
y
```
## Encrypt
Encrypt partition
```
cryptsetup luksFormat -v -s 512 -h sha512 /dev/nvme0n1p2
YES
<insert passwd>
```
luksFormat options good?

Open partition
```
cryptsetup open /dev/nvme0n1p2 cryptlvm
```
## Setup LVM
```
pvcreate /dev/mapper/cryptlvm
vgcreate arch /dev/mapper/cryptlvm
lvcreate -n swap  -L 20G -C y arch
lvcreate -n btrfs -l 100%FREE arch
```
Should i keep -C option?

## Format partitions
```
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/mapper/arch-swap
mkfs.btrfs /dev/mapper/arch-btrfs
```
should i specify btrfs and maybe swap labels with -L ... ?

# Mounting
Enable swap and mark as available
```
swapon /dev/mapper/arch-swap
swapon -a
```
Second command useful?

create btrfs subvolumes
```
mount /dev/mapper/arch-btrfs /mnt
cd /mnt

btrfs subvolume create @
btrfs subvolume create @home
btrfs subvolume create @snapshots
btrfs subvolume create @log
btrfs subvolume create @cache
btrfs subvolume create @tmp

cd ..
umount /mnt
```

mount btrfs subvolumes and BOOT partition
```
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@ /dev/mapper/arch-btrfs /mnt

mkdir /mnt/home
mkdir /mnt/.snapshots
mkdir /mnt/var
mkdir /mnt/var/log
mkdir /mnt/var/cache
mkdir /mnt/var/tmp

mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@home /dev/mapper/arch-btrfs /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@snapshots /dev/mapper/arch-btrfs /mnt/.snapshots
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@log /dev/mapper/arch-btrfs /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@cache /dev/mapper/arch-btrfs /mnt/var/cache
mount -o noatime,compress=zstd,space_cache=v2,discard=async,subvol=@tmp /dev/mapper/arch-btrfs /mnt/var/tmp
```
are these mount options good?

Mount boot partition
```
mkdir /mnt/boot
mount /dev/sda1 /mnt/boot
```

Command lsblk should now look like exambple

## Installing the system
```
pacstrap -K /mnt base base-devel linux linux-firmware linux-headers lvm2 btrfs-progs amd-ucode neovim
```
generate fstab
```
genfstab -U -p /mnt >> /mnt/etc/fstab
```
-U -p -L ?

change root
```
arch-chroot /mnt
```

## Rest of config
Execute base-install.sh script
```
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
vim /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >> /etc/locale.conf
echo "KEYMAP=de-latin1" >> /etc/vconsole.conf
echo "devstation" >> /etc/hostname
nvim /etc/hosts
```
change these, stolen

```
nvim /etc/mkinitcpio.conf
```
then
```
mkinitcpio -p linux
```

## Install and configure grub


```
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
```
change the directory to /boot/efi is you mounted the EFI partition at /boot/efi


Edit /etc/default/grub
```
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=<insert-UUID>:cryptlvm root=/dev/mapper/arch-btrfs drm.edid_firmware=edid/edid.bin amdgpu.freesync_video=1"
GRUB_DISABLE_OS_PROBER=false
```
You can omit the second line if you don't plan on installing os-prober.

Now you have to generate the grub config
```
grub-mkconfig -o /boot/grub/grub.cfg
```

## Create and configure your user

Replace <user> by the name you wish to assign your user
```
useradd -mG wheel libvirt <user>
passwd <user>
```

Edit the sudoers file
```
EDITOR=nvim visudo
```
Uncomment the line that gives anyone in the wheel group sudo permission (with password)
```
%wheel ALL=(ALL:ALL) ALL
```

## Finish and reboot
```
exit
umount -R /mnt
poweroff
```
Unplug your usb and turn on your computer


Special setup:

## 165Hz on Dynamic graphics mode + amd freesync:
place edid.bin at /usr/lib/firmware/edid/edid.bin

/etc/mkinitcpio.conf
```

MODULES=(btrfs nvidia nvidia_modeset nvidia_uvm nvidia_drm)

BINARIES=()

FILES=(/usr/lib/firmware/edid/edid.bin)

HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block encrypt lvm2 filesystems resume fsck)

```
Resume good for hibernate

/etc/default/grub
```
GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet cryptdevice=UUID=<insert-UUID>:cryptlvm root=/dev/mapper/arch-btrfs drm.edid_firmware=edid/edid.bin amdgpu.freesync_video=1"
```
make grub config
```
grub-mkconfig -o /boot/grub/grub.cfg
```

## Ctr2caps
