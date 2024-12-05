# Lenovo Legion Slim 7 Gen 7 AMD (16ARHA7)
{ pkgs, modulesPath, ... }:
let
  bootUUID = "AFCB-D880"; # The UUID of the boot partition.
  luksUUID = "bcf67e34-339e-40b9-8ffd-bec8f7f55248"; # The UUID of the locked LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Configure the kernel.
  boot = {
    #kernelPackages = pkgs.linuxPackages_latest;
    kernelPackages = pkgs.linuxKernel.packages.linux_lqx;

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
    };

    kernelModules = [ "kvm-amd" ];
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

  # Limit the number of cores Nix can use
  nix.settings.cores = 12;
}
