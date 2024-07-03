{ lib, config, ... }:
let
  cfg = config.aux.system.filesystem.btrfs;

  standardMountOpts = [ "compress=zstd" ];
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
      subvolumes = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Which subvolumes to mount. Leave as the default to create all standard subvolumes.";
        default = [
          "/"
          "/home"
          "/nix"
          "/var/log"
        ];
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
        "/" = lib.mkIf (builtins.elem "/" cfg.subvolumes) {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@"
            "compress=zstd"
          ];
        };
        "/boot" = {
          device = cfg.devices.boot;
          fsType = "vfat";
        };
        "/home" = lib.mkIf (builtins.elem "/home" cfg.subvolumes) {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@home"
            "compress=zstd"
          ];
        };
        "/var/log" = lib.mkIf (builtins.elem "/var/log" cfg.subvolumes) {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@log"
            "compress=zstd"
          ];
        };
        "/nix" = lib.mkIf (builtins.elem "/nix" cfg.subvolumes) {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@nix"
            "compress=zstd"
            "noatime"
          ];
        };
      }
      // lib.optionalAttrs cfg.swapFile.enable {
        "/swap" = {
          device = cfg.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@swap"
            "noatime"
          ];
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
