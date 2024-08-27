{
  config,
  lib,
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
    # Enable antenna aggregation
    extraModprobeConfig = ''
      options iwlwifi 11n_disable=8
    '';

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

  # Automatically scrub the RAID array weekly
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
      OnCalendar = "weekly";
      Persistent = true;
      Unit = "raid-scrub.service";
    };
  };

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Detect keyboard as "internal" so we can automatically disable the touchpad while typing
  # If this doesn't work, try changing "MatchName" to "AT Raw Set 2 keyboard"
  environment.etc."libinput/keyboard-touchpard.quirks" = {
    mode = "0600";
    text = ''
      [Microsoft Surface Type Cover Touchpad]
      MatchUdevType=touchpad
      MatchName=*Microsoft Surface Type Cover Touchpad
      AttrKeyboardIntegration=internal

      [Microsoft Surface Type Cover Keyboard]
      MatchUdevType=keyboard
      MatchName=*Microsoft Surface Type Cover Keyboard
      AttrKeyboardIntegration=internal
    '';
  };
}
