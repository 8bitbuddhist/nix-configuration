# Minisforum UM340
{
  modulesPath,
  namespace,
  pkgs,
  ...
}:
let
  bootUUID = "D2E7-FE8F"; # The UUID of the boot partition.
  luksUUID = "7b9c756c-ba9d-43fc-b935-7c77a70f5f1b"; # The UUID of the locked LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "nvme_core.default_ps_max_latency_us=0" ]; # (Allegedly) Fixes 84 degree reading on Samsung NVMe. See https://www.reddit.com/r/unRAID/comments/s4w79b/m2_drive_bad_temp_reading_seriously_84c/

    initrd.kernelModules = [
      "kvm-amd"
      "nvme"
      "xhci_pci"
      "ahci"
      "usb_storage"
      "usbhid"
      "sd_mod"
    ];

    # Enable support for building ARM64 packages
    binfmt.emulatedSystems = [ "aarch64-linux" ];
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
}
