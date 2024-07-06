{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:

let
  bootUUID = "FC20-D155"; # The UUID of the boot partition.
  luksUUID = "9fdc521b-a037-4070-af47-f54da03675e4"; # The UUID of the locked LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # Enable mdadm for Sapana (RAID 5 primary storage).
    swraid = {
      enable = true;
      mdadmConf = ''
        ARRAY /dev/md/Sapana metadata=1.2 UUID=51076daf:efdb34dd:bce48342:3b549fcb
        MAILADDR ${config.secrets.users.aires.email}
      '';
    };
  };

  # Configure the main filesystem.
  aux.system.filesystem = {
    enable = true;
    partitions = {
      boot = "/dev/disk/by-uuid/${bootUUID}";
      luks = "/dev/disk/by-uuid/${luksUUID}";
    };
    swapFile = {
      enable = true;
      size = 16384;
    };
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
