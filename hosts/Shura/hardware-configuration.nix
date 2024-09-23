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

  # Detect keyboard as "internal" so we can automatically disable the touchpad while typing
  # If this doesn't work, try changing "MatchName" to "AT Raw Set 2 keyboard"
  environment.etc."libinput/keyboard-touchpard.quirks" = {
    mode = "0600";
    text = ''
      [Serial Keyboards]
      MatchUdevType=keyboard
      MatchName=ITE Tech. Inc. ITE Device(8258) Keyboard
      AttrKeyboardIntegration=internal
    '';
  };

  # Limit the number of cores Nix can use
  nix.settings.cores = 12;
}
