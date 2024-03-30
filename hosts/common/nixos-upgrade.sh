#!/usr/bin/env bash
# Update NixOS system while printing out the different packages to install.
# Inspiration: https://blog.tjll.net/previewing-nixos-system-updates/
set -e
OPERATION="boot"		# Which update method to use. Defaults to "boot", which applies updates on reboot.

if ! [ -z "$1" ]; then
	OPERATION=$1
fi

echo "Using installation mode: $OPERATION"

cd ~/Development/nix-configuration
nix flake update
nixos-rebuild build --flake .
echo "Updates to apply:"
nix store diff-closures /run/current-system ./result | awk '/[0-9] →|→ [0-9]/ && !/nixos/' || echo

read -p "Continue with upgrade (y/n) ? " choice
case "$choice" in 
  y|Y|yes ) sudo nixos-rebuild $OPERATION --flake .;;
  n|N|no ) echo "Upgrade cancelled.";;
  * ) echo "Invalid option. Upgrade cancelled.";;
esac