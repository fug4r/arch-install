# Full-disk encryption on Arch Linux with LVM,LUKS,BTRFS and SWAP Hibernate

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
