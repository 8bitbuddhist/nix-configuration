# Raspberry Pi 4B
# See https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi_4
{
  config,
  lib,
  pkgs,
  modulesPath,
  nixos-hardware,
  ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.loader = lib.mkForce {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  #boot.kernelParams = [
  #	"console=serial0,115200n8"
  #];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  hardware.enableRedistributableFirmware = true;
  networking.wireless.enable = true;

  hardware = {
    raspberry-pi."4" = {
      apply-overlays-dtmerge.enable = true;
    };

    deviceTree = {
      enable = true;
      filter = "*rpi-4-*.dtb";
    };
  };
}
