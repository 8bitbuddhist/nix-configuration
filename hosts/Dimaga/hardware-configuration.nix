{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  primaryDisk = "/dev/disk/by-id/";
  luksDevice = "";
  standardMountOpts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "nvme"
        "usb_storage"
        "sd_mod"
        "sdhci_pci"
      ];
      luks.devices."luks-${luksDevice}" = {
        device = "/dev/disk/by-uuid/${luksDevice}";
        crypttabExtraOpts = [ "tpm2-device=auto" ]; # Enable TPM auto-unlocking
      };
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = primaryDisk;
      fsType = "btrfs";
      options = [ "subvol=@" ] ++ standardMountOpts;
    };
    "/home" = {
      device = primaryDisk;
      fsType = "btrfs";
      options = [ "subvol=@home" ] ++ standardMountOpts;
    };
    "/nix" = {
      device = primaryDisk;
      fsType = "btrfs";
      options = [ "subvol=@nix" ] ++ standardMountOpts;
    };
    "/swap" = {
      device = primaryDisk;
      fsType = "btrfs";
      options = [ "subvol=@swap" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/AFCB-D880";
      fsType = "vfat";
    };
  };

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.wlp2s0.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
