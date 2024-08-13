# Disk encryption on Arch Linux with LVM,LUKS,BTRFS and SWAP Hibernate

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
LVM Partition
```
n
↵
↵
↵
8e00
```
Write and quit gdisk
```
w
y
```

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

## Ctr2caps
