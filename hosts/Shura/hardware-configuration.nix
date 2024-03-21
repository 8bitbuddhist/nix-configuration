# Lenovo Legion S7 16ARHA7 configuration
{ config, lib, pkgs, modulesPath, ... }:
let
	lenovo-speaker-fix-module = pkgs.callPackage ./patches/lenovo-speaker-fix.nix {
    # Make sure the module targets the same kernel as your system is using.
    kernel = config.boot.kernelPackages.kernel;
  };
in
{
	imports = [
		(modulesPath + "/installer/scan/not-detected.nix")
	];

	# Configure the kernel.
	boot = {
		# First, install the latest Zen kernel
		kernelPackages = pkgs.linuxPackages_zen;

		# Hardware defaults detected by nixos-generate-configuration
		initrd = {
			# SystemD in the initrd is required for TPM auto-unlocking.
			# See https://discourse.nixos.org/t/full-disk-encryption-tpm2/29454/2
			# If the LUKS volume is recently created, run this command to bind it to the TPM:
			#	sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/<device>
			systemd.enable = true;

			availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" "tpm_crb" ];
			kernelModules = [ "amdgpu" "tpm_crb" ];
			luks.devices."luks-bcf67e34-339e-40b9-8ffd-bec8f7f55248" = {
				device = "/dev/disk/by-uuid/bcf67e34-339e-40b9-8ffd-bec8f7f55248";
				crypttabExtraOpts = [ "tpm2-device=auto" ];	# Enable TPM auto-unlocking
			};
		};
		
		kernelModules = [
			"kvm-amd"
		];

		# Add kernel patch to enable sound over the speakers.
		extraModulePackages = [
			(lenovo-speaker-fix-module.overrideAttrs (_: {
				patches = [ ./patches/lenovo_16ARHA7_sound_fix.patch ];
			}))
		];
	};

	fileSystems = {
		"/" = { device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
			fsType = "btrfs";
			options = [ "subvol=@,compress=zstd" ];
		};
		"/home" = { device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
			fsType = "btrfs";
			options = [ "subvol=@home,compress=zstd" ];
		};
		"/swap" = { device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
			fsType = "btrfs";
			options = [ "subvol=@swap" ];
		};
		"/boot" = { 
			device = "/dev/disk/by-uuid/AFCB-D880";
			fsType = "vfat";
		};
	 };

	swapDevices = [{
		device = "/swap/swapfile";
		size = 16384;
	}];

	# Enable AMDGPU
	hardware = {
		opengl = {
			driSupport = true; # This is already enabled by default, but just in case.
			driSupport32Bit = true; # For 32 bit applications.

			extraPackages = with pkgs; [
				rocmPackages.clr.icd	# OpenCL
			];
		};
	};

	networking = {
		# Enables DHCP on each ethernet and wireless interface. In case of scripted networking
		# (the default) this is the recommended approach. When using systemd-networkd it's
		# still possible to use this option, but it's recommended to use it in conjunction
		# with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
		useDHCP = lib.mkDefault true;
		# networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

		# Set the hostname.
		hostName = "Shura";
	};

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
	hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
