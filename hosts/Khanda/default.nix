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
						enableTray = false;
					};
				};
			};
		};
	};

	# Limit number of simultaneous builds so we have two free cores.
	# 	5 max jobs * 2 cores each = 10 cores in total.
	nix.settings = {
		max-jobs = 2;
		cores = 10;
	};

	# Configure the virtual machine created by nixos-rebuild build-vm
	virtualisation.vmVariant.virtualisation = {
		memorySize =	2048;
		cores = 2;
	};
}
