# Raspberry Pi 4B
# See https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4
{
  lib,
  modulesPath,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    # Enable audio devices
    kernelParams = [
      "snd_bcm2835.enable_hdmi=1"
      "snd_bcm2835.enable_headphones=1"
      "dtparam=audio=on"
    ];

    # Configure bootloader
    loader = lib.mkForce {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  #boot.kernelParams = [
  #	"console=serial0,115200n8"
  #];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
    options = [
      "lazytime" # Reduce atime writes: https://wiki.archlinux.org/title/Fstab#atime_options
      "data=journal" # Commit to the journal before writing to the filesystem.
      "journal_async_commit"
    ];
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  hardware = {
    enableRedistributableFirmware = true;
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
      fkms-3d.enable = true; # Enable GPU
    };

    deviceTree.enable = true;
  };
}
