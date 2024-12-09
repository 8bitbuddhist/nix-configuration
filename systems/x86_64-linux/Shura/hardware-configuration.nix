# Lenovo Legion Slim 7 Gen 7 AMD (16ARHA7)
{
  pkgs,
  modulesPath,
  namespace,
  ...
}:
let
  bootUUID = "AFCB-D880"; # The UUID of the boot partition.
  luksUUID = "bcf67e34-339e-40b9-8ffd-bec8f7f55248"; # The UUID of the locked LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Configure the kernel.
  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernelModules = [ "kvm-amd" ];

    # Hardware defaults detected by nixos-generate-configuration
    initrd.availableKernelModules = [
      "kvm-amd"
      "nvme"
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "rtsx_pci_sdmmc"
    ];
  };

  # Configure the main filesystem.
  ${namespace}.filesystem = {
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
