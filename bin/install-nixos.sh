#!/usr/bin/env bash
# Script to install a brand new NixOS installation.
# Formats the drive provided, then runs nixos-install.

set -e

# Configuration parameters
ask_root_password=true	# Prompt for a root user password
flakeDir="."			# Where the flake.nix file is stored
boot_drive="/dev/disk/by-uuid/B2D7-96C3"	# The drive to install the bootloader to
luks_drive="/dev/nvme0n1p2"
root_drive="/dev/mapper/nixos-crypt"	# The partition to install NixOS to

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# FIXME: Need to get the UUID from the newly-created LUKS partition, then use it going forward.
cryptsetup --label=nixos-crypt --type=luks2 luksFormat $root_drive
cryptsetup luksOpen $root_drive nixos-crypt
mkfs.btrfs -L nixos $root_drive
mount /dev/mapper/nixos-crypt /mnt
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
mount -o subvol=@log $root_drive /mnt/var/log
mount -o subvol=@nix $root_drive /mnt/nix
mount -o subvol=@swap $root_drive /mnt/swap
echo "Disks partitioned and mounted to /mnt."

# Generate hardware-configuration.nix
nixos-generate-config --no-filesystems --dir /home/nixos
echo "Configuration files generated and saved to /home/nixos."

echo "Setup complete!"
echo "To install, set up your system's configuration files under ./hosts/yourHost and add it to flake.nix."
echo "Then, run the following command:"
echo "nixos-install --verbose --root /mnt --flake $flakeDir#Khanda --max-jobs 1 --cores 10 $( (( ask_root_password == false )) && echo "--no-root-password" )"

exit 0

