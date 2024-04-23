# Surface Pro 7
{ config, lib, pkgs, modulesPath, ... }:

{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
	];
/*
	boot = {
		initrd = {
			availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "usbhid" "sd_mod" ];
			kernelModules = [ ];
			luks.devices."luks-5a91100b-8ed9-4090-b1d8-d8291000fe38".device = "/dev/disk/by-uuid/5a91100b-8ed9-4090-b1d8-d8291000fe38";
		};

		kernelModules = [ "kvm-intel" ];
		extraModulePackages = [ ];
	};

	fileSystems = {
		"/" = {
			device = "/dev/disk/by-uuid/76d67291-5aed-4f2a-b71f-1c2871cefe24";
			fsType = "btrfs";
			options = [ "subvol=@,compress=zstd" ];
		};
		"/boot" = {
			device = "/dev/disk/by-uuid/0C53-A645";
			fsType = "vfat";
		};
	};
*/
	swapDevices = [{
		device = "/swapfile";
		size = 4096;
	}];

	networking = {
		useDHCP = lib.mkDefault true;
		hostName = "Khanda";
	};

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
