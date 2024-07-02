{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  luksPartition = "/dev/disk/by-uuid/dfb4fc8f-e82b-43a1-91c1-a77acb6337cb";
  luksDevice = "9fdc521b-a037-4070-af47-f54da03675e4";
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
      device = luksPartition;
      fsType = "btrfs";
      options = [ "subvol=@" ] ++ standardMountOpts;
    };
    "/home" = {
      device = luksPartition;
      fsType = "btrfs";
      options = [ "subvol=@home" ] ++ standardMountOpts;
    };
    "/nix" = {
      device = luksPartition;
      fsType = "btrfs";
      options = [ "subvol=@nix" ] ++ standardMountOpts;
    };
    "/swap" = {
      device = luksPartition;
      fsType = "btrfs";
      options = [ "subvol=@swap" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/FC20-D155";
      fsType = "vfat";
    };
  };

  swapDevices = [
    {
      device = "/swap/swapfile";
      size = 16384;
    }
  ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking = {
    hostName = "Dimaga";
    useDHCP = lib.mkDefault true;
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
