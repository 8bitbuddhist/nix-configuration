#!/usr/bin/env bash
# Script to setup a drive for a brand new NixOS installation.

set -e

# Configuration parameters
ask_root_password=false	# Whether to prompt for a root user password
boot_partition="" # The drive to install the bootloader to
luks_partition="" # The drive partition to create the LUKS container on
root_partition="/dev/mapper/nixos-crypt" # The partition to install NixOS to

function usage() {
	echo "Usage: format-drives.sh [--boot boot-partition-path] [--luks luks-partition-path] [--ask-root-password]"
	echo "Options:"
	echo "	-h | --help	Show this help screen."
	echo "	-b | --boot <path>	      The path to the boot drive (e.g. /dev/nvme0n1p1)."
	echo "  -l | --luks <path>        The path to the partition to create the LUKS container on (e.g. /dev/nvme0n1p2)."
	echo "  -a | --ask-root-password  Sets a password for the root user account."
	exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
      --ask-root-password|-a)
			ask_root_password=true
			shift
			;;
	  --boot|-b)
		   boot_partition=$1
			shift
			;;
		--luks|-l)
			luks_partition=1
			shift
			;;
		--help|-h)
			usage
			shift
			;;
		*)
			break
			;;
	esac
done

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cryptsetup --label=nixos-crypt --type=luks2 luksFormat $luks_partition
cryptsetup luksOpen $luks_partition nixos-crypt
mkfs.btrfs -L nixos $root_partition
mount /dev/mapper/nixos-crypt /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@nix
btrfs subvolume create /mnt/@swap
umount /mnt

mount -o subvol=@ $root_partition /mnt
mkdir -p /mnt/{boot,home,var/log,nix,swap}
mount $boot_partition /mnt/boot
mount -o subvol=@home $root_partition /mnt/home
mount -o subvol=@log $root_partition /mnt/var/log
mount -o subvol=@nix $root_partition /mnt/nix
mount -o subvol=@swap $root_partition /mnt/swap
echo "Disks partitioned and mounted to /mnt."

# Generate hardware-configuration.nix
nixos-generate-config --no-filesystems --dir /home/nixos
echo "Configuration files generated and saved to /home/nixos."

echo "Setup complete!"
echo "To install, set up your system's configuration files under ./hosts/yourHost and add it to flake.nix."
echo "Then, run the following command:"
echo "nixos-install --verbose --root /mnt --flake [path-to-flake.nix] $( (( ask_root_password == false )) && echo "--no-root-password" )"

exit 0

