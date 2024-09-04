# Minisforum UM340
{ modulesPath, ... }:
let
  bootUUID = "0120-A755"; # The UUID of the boot partition.
  luksUUID = "2c76c660-3573-4622-8771-f23fa7ee302a"; # The UUID of the locked LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    supportedFilesystems = [ "btrfs" ];
    kernelModules = [ "kvm-amd" ];

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

    # Enable support for building ARM64 packages
    binfmt.emulatedSystems = [ "aarch64-linux" ];
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

  # Automatically scrub the RAID array monthly
  systemd.services."raid-scrub" = {
    description = "Periodically scrub RAID volumes for errors.";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = "echo check > /sys/block/md127/md/sync_action";
  };
  systemd.timers."raid-scrub" = {
    description = "Periodically scrub RAID volumes for errors.";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "monthly";
      Persistent = true;
      Unit = "raid-scrub.service";
    };
  };
}
