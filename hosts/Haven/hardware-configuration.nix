# Minisforum UM340
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Format and configure the disk using Disko
  host.base.disko = {
    enable = false;
    primaryDisk = "nvme0n1";
    enableTPM = true;
    swapFile = {
      enable = true;
      size = "16G";
    };
  };

  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];

    initrd = {
      supportedFilesystems = [ "btrfs" ];
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
        "btrfs"
      ];
      kernelModules = [ ];
    };

    # Enable mdadm for Sapana (RAID 5 primary storage).
    swraid = {
      enable = true;
      mdadmConf = lib.mkIf (config.networking.hostName == "Haven") ''
        ARRAY /dev/md/Sapana metadata=1.2 UUID=51076daf:efdb34dd:bce48342:3b549fcb
        MAILADDR ${config.secrets.users.aires.email}
      '';
    };
  };

  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "Haven";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
