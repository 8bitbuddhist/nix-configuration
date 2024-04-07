{ config, lib, pkgs, modulesPath, ... }:

{
	imports =
		[ (modulesPath + "/installer/scan/not-detected.nix") ];

	boot = {
		supportedFilesystems = [ "btrfs" ];
		kernelModules = [ "kvm-amd" ];
		extraModulePackages = [ ];

		initrd = {
			supportedFilesystems = [ "btrfs" ];		
			availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usb_storage" "usbhid" "sd_mod" "btrfs" ];
			kernelModules = [ ];
		};
	};

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-uuid/2c76c660-3573-4622-8771-f23fa7ee302a";
			fsType = "btrfs";
			options = [ "subvol=@,compress=zstd" ];
		};
		"/home" = {
			device = "/dev/disk/by-uuid/2c76c660-3573-4622-8771-f23fa7ee302a";
			fsType = "btrfs";
			options = [ "subvol=@home,compress=zstd" ];
		};
		"/swap" = {
			device = "/dev/disk/by-uuid/2c76c660-3573-4622-8771-f23fa7ee302a";
			fsType = "btrfs";
			options = [ "subvol=@swap" ];
		};
		"/boot" = {
			device = "/dev/disk/by-uuid/0120-A755";
			fsType = "vfat";
		};
	};

	swapDevices = [{
		device = "/swap/swapfile";
		size = 16384;
	}];

	networking = {
		useDHCP = lib.mkDefault true;
		hostName = "Haven";
	};

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
