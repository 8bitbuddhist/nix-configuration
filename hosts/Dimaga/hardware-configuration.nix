{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  luksUUID = "9fdc521b-a037-4070-af47-f54da03675e4";
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
      luks.devices."luks-${luksUUID}" = {
        device = "/dev/disk/by-uuid/${luksUUID}";
        crypttabExtraOpts = [ "tpm2-device=auto" ]; # Enable TPM auto-unlocking
      };
    };
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
  };

  # Configure the main filesystem.
  aux.system.filesystem.btrfs = {
    enable = true;
    devices = {
      boot = "/dev/disk/by-uuid/FC20-D155";
      btrfs = "/dev/disk/by-uuid/${luksUUID}";
    };
    swapFile = {
      enable = true;
      size = 16384;
    };
  };

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
