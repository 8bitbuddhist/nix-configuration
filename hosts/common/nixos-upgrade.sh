#!/usr/bin/env bash
# Update NixOS system while printing out the different packages to install.
# Inspiration: https://blog.tjll.net/previewing-nixos-system-updates/
set -e
OPERATION="boot"		# Which update method to use. Defaults to "boot", which applies updates on reboot.
AUTOACCEPT=false		# Whether to automatically apply the update or ask for permission.

function usage() {
	echo "Usage: nixos-upgrade.sh [ -y | --auto-accept ] [-o | --operation]"
	echo "Options:"
	echo "	-h | --help		Show this help screen."
	echo "	-y | --auto-accept	Automatically approve pending changes."
	echo "	-o | --operation	Which update operation to perform (switch, boot, etc.). Defaults to boot."
	exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
	  -y|-Y|--auto-accept)
		  AUTOACCEPT=true
			shift
			;;
		-o|-O|--operation)
		  OPERATION=$2
			shift
			;;
		-h|--help)
			usage
			shift
			;;
		*)
			break
			;;
	esac
done

echo "Using installation mode: $OPERATION"

cd ~/Development/nix-configuration
nix flake update
nixos-rebuild build --flake .
echo "Updates to apply:"
nix store diff-closures /run/current-system ./result | awk '/[0-9] →|→ [0-9]/ && !/nixos/' || echo

if [ $AUTOACCEPT == false ]; then
	read -p "Continue with upgrade (y/n) ? " choice
	case "$choice" in 
		y|Y|yes ) echo "Running nixos-rebuild $OPERATION :";;
		n|N|no ) echo "Upgrade cancelled." && exit;;
		* ) echo "Invalid option. Upgrade cancelled." && exit;;
	esac
fi

sudo nixos-rebuild $OPERATION --flake .

echo "Updating Flatpaks:"
flatpak update
