{ lib, config, ... }:
let
  cfg = config.aux.system.filesystem.btrfs;

  standardMountOpts = [
    "compress=zstd"
    "discard=async"
    "noatime"
  ];
in
{
  options = {
    aux.system.filesystem.btrfs = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables standard BTRFS subvolumes and parameters.");
      devices = {
        boot = lib.mkOption {
          type = lib.types.str;
          description = "The ID of your boot partition. Use /dev/disk/by-uuid for best results.";
          default = "";
        };
        btrfs = lib.mkOption {
          type = lib.types.str;
          description = "The ID of your BTRFS partition. Use /dev/disk/by-uuid for best results.";
          default = "";
        };
      };
      swapFile = {
        enable = lib.mkEnableOption (lib.mdDoc "Enables the creation of a swap file.");
        size = lib.mkOption {
          type = lib.types.int;
          description = "The size of the swap file to create in MB (defaults to 8192, or ~8 gigabytes).";
          default = 8192;
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {

    # Check for blank parameters
    assertions = [
      {
        assertion = cfg.devices.btrfs != "";
        message = "Please specify a BTRFS partition to use as a filesystem.";
      }
      {
        assertion = cfg.devices.boot != "";
        message = "Please specify a boot partition to use as a filesystem.";
      }
    ];
    fileSystems =
      {
        "/" = {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [ "subvol=@" ] ++ standardMountOpts;
        };
        "/boot" = {
          device = cfg.devices.boot;
          fsType = "vfat";
        };
        "/home" = {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [ "subvol=@home" ] ++ standardMountOpts;
        };
        "/var/log" = {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [ "subvol=@log" ] ++ standardMountOpts;
        };
        "/nix" = {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [ "subvol=@nix" ] ++ standardMountOpts;
        };
      }
      // lib.optionalAttrs cfg.swapFile.enable {
        "/swap" = {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [ "subvol=@swap" ];
        };
      };

    swapDevices = lib.mkIf cfg.swapFile.enable [
      {
        device = "/swap/swapfile";
        size = cfg.swapFile.size;
      }
    ];
  };
}
