{ config, pkgs, lib, ... }:

# Configuration options unique to Shura

let	
	# Copy bluetooth device configs
	shure-aonic-bluetooth = pkgs.writeText "info" (builtins.readFile ./bluetooth/shure-aonic-bluetooth-params);
	xbox-elite-bluetooth = pkgs.writeText "info" (builtins.readFile ./bluetooth/xbox-elite-controller-bluetooth-params);
	mano-touchpad-bluetooth = pkgs.writeText "info" (builtins.readFile ./bluetooth/mano-touchpad-bluetooth-params);

	# Use gremlin user's monitor configuration for GDM (desktop monitor primary). See https://discourse.nixos.org/t/gdm-monitor-configuration/6356/4
	monitorsXmlContent = builtins.readFile ./monitors.xml;
	monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
in
{
	imports = [ 
		./hardware-configuration.nix
		../common
	];

	system.stateVersion = "24.05";

	host = {
		role = "workstation";
		apps = {
			development = {
				enable = true;
				kubernetes.enable = true;
			};
			dj.enable = true;
			gaming.enable = true;
			kdeconnect.enable = true;
			media.enable = true;
			office.enable = true;
			recording.enable = true;
			social.enable = true;
			writing.enable = true;
		};
		ui = {
			flatpak.enable = true;
			gnome.enable = true;
		};
		users = {
			aires = {
				enable = true;
				services.syncthing = {
					enable = true;
					enableTray = false;	# Recent versions of STT don't recognize Gnome's tray. Uninstalling for now.
				};
			};
			gremlin = {
				enable = true;
				services.syncthing = {
					enable = true;
					enableTray = false;
				};
			};
		};
	};

	# Move files into target system
	systemd.tmpfiles.rules = [
		# Use gremlin user's monitor config for GDM (defined above)
		"L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"

		# Install Bluetooth device profiles
		"d /var/lib/bluetooth/AC:50:DE:9F:AB:88/ 0700 root root"	# First, make sure the directory exists
		"L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/00:0E:DD:72:2F:0C/info - - - - ${shure-aonic-bluetooth}"
		"L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/F4:6A:D7:3A:16:75/info - - - - ${xbox-elite-bluetooth}"
		"L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/F8:5D:3C:7D:9A:00/info - - - - ${mano-touchpad-bluetooth}"
	];

	# Configure the virtual machine created by nixos-rebuild build-vm
	virtualisation.vmVariant.virtualisation = {
		memorySize =	4096;
		cores = 4;
	};
}
