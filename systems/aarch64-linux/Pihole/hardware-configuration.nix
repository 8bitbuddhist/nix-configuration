# Raspberry Pi 4B
# See https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4
{
  config,
  lib,
  modulesPath,
  namespace,
  pkgs,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    kernelParams = [
      # Enable audio
      "snd_bcm2835.enable_hdmi=1"
      "snd_bcm2835.enable_headphones=1"
      "dtparam=audio=on"
      # Enable cgroups memory for Kubernetes in Docker. See https://github.com/kubernetes-sigs/kind/issues/3503
      "cgroup_enable=memory"
      "cgroup_memory=1"
    ];

    # Switch to a compatible bootloader
    loader = lib.mkForce {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
      fsType = "ext4";
      options = [
        "lazytime" # Reduce atime writes: https://wiki.archlinux.org/title/Fstab#atime_options
        "data=journal" # Commit to the journal before writing to the filesystem.
        "journal_async_commit"
      ];
    };
  };

  swapDevices = [
    {
      device = "/swapfile";
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
