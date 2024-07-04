{ lib, config, ... }:
let
  cfg = config.aux.system.filesystem;

  standardMountOpts = [ "compress=zstd" ];
in
{
  options = {
    aux.system.filesystem = {
      btrfs = {
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
      luks = {
        enable = lib.mkEnableOption (
          lib.mkDoc "Enables an encrypted LUKS container for the BTRFS partition."
        );
        uuid = lib.mkOption {
          type = lib.types.str;
          description = "The UUID of the encrypted LUKS volume.";
        };
      };
    };
  };

  config = lib.mkIf cfg.btrfs.enable {

    # Check for blank parameters
    assertions = [
      {
        assertion = cfg.btrfs.devices.btrfs != "";
        message = "Please specify a BTRFS partition to use as a filesystem.";
      }
      {
        assertion = cfg.btrfs.devices.boot != "";
        message = "Please specify a boot partition to use as a filesystem.";
      }
    ];
    boot.initrd.luks.devices = lib.mkIf cfg.luks.enable {
      "luks-${cfg.luks.uuid}" = {
        device = "/dev/disk/by-uuid/${cfg.luks.uuid}";
        # Enable TPM auto-unlocking if configured
        crypttabExtraOpts = lib.mkIf config.aux.system.bootloader.tpm2.enable [ "tpm2-device=auto" ];
      };
    };
    fileSystems =
      {
        "/" = {
          device = cfg.btrfs.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@"
            "compress=zstd"
          ];
        };
        "/boot" = {
          device = cfg.btrfs.devices.boot;
          fsType = "vfat";
        };
        "/home" = {
          device = cfg.btrfs.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@home"
            "compress=zstd"
          ];
        };
        "/var/log" = {
          device = cfg.btrfs.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@log"
            "compress=zstd"
          ];
        };
        "/nix" = {
          device = cfg.btrfs.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@nix"
            "compress=zstd"
            "noatime"
          ];
        };
      }
      // lib.optionalAttrs cfg.btrfs.swapFile.enable {
        "/swap" = {
          device = cfg.btrfs.devices.btrfs;
          fsType = "btrfs";
          options = [
            "subvol=@swap"
            "noatime"
          ];
        };
      };

    swapDevices = lib.mkIf cfg.btrfs.swapFile.enable [
      {
        device = "/swap/swapfile";
        size = cfg.btrfs.swapFile.size;
      }
    ];
  };
}
