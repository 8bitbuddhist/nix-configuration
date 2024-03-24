{ pkgs, ... }:

# Settings specific to Dimaga

{
	imports = [
		./hardware-configuration.nix
		../common
	];

	system.stateVersion = "24.05";

	host = {
		role = "workstation";
		apps = {
			development.enable = true;
			kdeconnect.enable = true;
			media.enable = true;
			office.enable = true;
			pandoc.enable = true;
		};
		ui = {
			flatpak.enable = true;
			gnome.enable = true;
		};
		users = {
			aires = {
				enable = true;
				autologin = true;
				services = {
					syncthing = {
						enable = true;
						autostart = true;
						enableTray = true;
					};
				};
			};
		};
	};

	# Configure the virtual machine created by nixos-rebuild build-vm
	virtualisation.vmVariant.virtualisation = {
		memorySize =	2048;
		cores = 2;
	};
}