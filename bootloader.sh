#!/bin/sh

mount -t devtmpfs none /dev
mount -t proc none /proc
mount -t sysfs none /sys

mount -o ro @squashfsContainerDevice@ /mnt
mount -o ro /mnt@squashfsPath@ /nix/store

system="$(readlink -f /nix/store/_system)"

kexec --load "$system/kernel" \
  --initrd "$system/initrd" \
  --dtb /tegra30-ouya.dtb \
  --command-line "init=$system/init $(cat $system/kernel-params)" \
  --mem-min=0x8E000000
kexec -e

exec /bin/sh
