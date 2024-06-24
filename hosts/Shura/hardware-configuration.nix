# Lenovo Legion Slim 7 Gen 7 AMD (16ARHA7)
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Configure the kernel.
  boot = {
    # First, install the latest Zen kernel
    kernelPackages = pkgs.linuxPackages_zen;

    # Hardware defaults detected by nixos-generate-configuration
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
      ];
      luks.devices."luks-bcf67e34-339e-40b9-8ffd-bec8f7f55248" = {
        device = "/dev/disk/by-uuid/bcf67e34-339e-40b9-8ffd-bec8f7f55248";
        crypttabExtraOpts = [ "tpm2-device=auto" ]; # Enable TPM auto-unlocking
      };
    };

    kernelModules = [ "kvm-amd" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
      fsType = "btrfs";
      options = [ "subvol=@,compress=zstd,discard" ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
      fsType = "btrfs";
      options = [ "subvol=@home,compress=zstd,discard" ];
    };
    "/swap" = {
      device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
      fsType = "btrfs";
      options = [ "subvol=@swap" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/AFCB-D880";
      fsType = "vfat";
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16384;
    }
  ];

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
}
