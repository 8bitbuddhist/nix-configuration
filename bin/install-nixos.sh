#!/usr/bin/env bash
# Script to install a brand new NixOS installation.
# Formats the drive provided, then runs nixos-install.

set -e

# Configuration parameters
ask_root_password=true	# Prompt for a root user password
flakeDir="."			# Where the flake.nix file is stored
boot_drive="/dev/disk/by-uuid/whatever"	# The drive to install the bootloader to
root_drive="/dev/disk/by-id/whatever"	# The partition to install NixOS to

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cryptsetup --allow-discards --label=nixos-crypt --type=luks2 luksFormat $root_drive
cryptsetup luksOpen $root_drive nixos-crypt
mount /dev/mapper/nixos-crypt /mnt
mkfs.btrfs -L nixos /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@swap
umount /mnt

mount -o subvol=@ $root_drive /mnt
mkdir -p /mnt/{boot,home,var/log,nix,swap}
mount $boot_drive /mnt/boot
mount -o subvol=@home $root_drive /mnt/home
mount -o subvol=@log $root_drive /var/log
mount -o subvol=@nix $root_drive /mnt/nix
mount -o subvol=@swap $root_drive /mnt/swap

# Create swapfile
btrfs filesystem mkswapfile --size $(free -h --si | grep Mem: | awk '{print $2}') --uuid clear /mnt/swap/swapfile

nixos-install --verbose --root /mnt --flake $flakeDir $( (( ask_root_password == false )) && echo "--no-root-password" )

exit 0

