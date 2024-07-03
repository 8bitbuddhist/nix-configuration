# Lenovo Legion Slim 7 Gen 7 AMD (16ARHA7)
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  bootUUID = "AFCB-D880"; # The UUID of the boot partition.
  luksUUID = "bcf67e34-339e-40b9-8ffd-bec8f7f55248"; # The UUID of the locked LUKS partition.
  rootUUID = "b801fbea-4cb5-4255-bea9-a2ce77d1a1b7"; # The UUID of the unlocked filesystem partition.
in
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
      luks.devices."luks-${luksUUID}" = {
        device = "/dev/disk/by-uuid/${luksUUID}";
        crypttabExtraOpts = [ "tpm2-device=auto" ]; # Enable TPM auto-unlocking
      };
    };

    kernelModules = [ "kvm-amd" ];
  };

  # Configure the main filesystem.
  aux.system.filesystem.btrfs = {
    enable = true;
    devices = {
      boot = "/dev/disk/by-uuid/${bootUUID}";
      btrfs = "/dev/disk/by-uuid/${rootUUID}";
    };
    swapFile = {
      enable = true;
      size = 16384;
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
}
