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
			development.enable = true;
      dj.enable = true;
			gaming.enable = true;
			hugo.enable = true;
      media.enable = true;
      office.enable = true;
			pandoc.enable = true;
			recording.enable = true;
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
					enableTray = true;
				};
			};
			gremlin = {
				enable = true;
				services.syncthing = {
					enable = true;
					enableTray = true;
				};
			};
		};
	};

	# Configure users
	users.users = {
		aires = {
			extraGroups = [ "libvirt" "gremlin" ];
		};
		gremlin = {
			extraGroups = [ "libvirt" ];
		};
	};

	# Add packages specific to Shura
	environment.systemPackages = with pkgs; [
		kubectl
		kubevirt	# Virtctl command-line tool
		linuxKernel.packages.linux_zen.xpadneo	# Xbox controller driver
	];

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
		memorySize =  4096;
		cores = 4;
	};

	# FIXME: Add extra boot entry for the recovery image. This doesn't work with lanzaboote though :(
	# NixOS config: https://nixos.org/manual/nixos/stable/options.html#opt-boot.loader.systemd-boot.extraEntries
	# Systemd-boot config: https://wiki.archlinux.org/title/Systemd-boot#Adding_loaders
	# Booting an ISO from disk: https://www.reddit.com/r/archlinux/comments/qy281v/boot_an_archlinux_iso_directly_from_my_boot_using/ 
	boot.loader.systemd-boot.extraEntries = {
		"nixos-live.conf" = ''
			title NixOS
			linux /live/vmlinuz-linux
			initrd /live/initramfs-linux.img
			options img_dev=/dev/nvme0n1p3 img_loop=nixos-gnome-23.11.3019.8bf65f17d807-x86_64-linux.isosudo  copytoram
		'';
	};
}
