{ lib, config, ... }:
let
  cfg = config.aux.system.filesystem;

  # LUKS partition will decrypt to /dev/mapper/nixos-root
  decryptPart = "nixos-root";
  decryptPath = "/dev/mapper/${decryptPart}";
in
{
  options = {
    aux.system.filesystem = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables standard BTRFS subvolumes and parameters.");
      partitions = {
        boot = lib.mkOption {
          type = lib.types.str;
          description = "The ID of your boot partition. Use /dev/disk/by-uuid for best results.";
          default = "";
        };
        luks = lib.mkOption {
          type = lib.types.str;
          description = "The ID of your LUKS partition. Use /dev/disk/by-uuid for best results.";
          default = "";
        };
      };
      discard = lib.mkOption {
        type = lib.types.bool;
        description = "Whether to enable TRIM for SSD and NVMe drives. Defaults to true.";
        default = true;
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
        assertion = cfg.partitions.luks != "";
        message = "Please specify a LUKS partition to use as the root filesystem.";
      }
      {
        assertion = cfg.partitions.boot != "";
        message = "Please specify your boot partition.";
      }
    ];
    boot.initrd.luks.devices.${decryptPart} = {
      device = cfg.partitions.luks;
      # Enable TPM auto-unlocking if configured
      crypttabExtraOpts = lib.mkIf config.aux.system.bootloader.tpm2.enable [ "tpm2-device=auto" ];
    };
    fileSystems =
      {
        "/" = {
          device = decryptPath;
          fsType = "btrfs";
          options = [
            "subvol=@"
            "compress=zstd"
          ] ++ lib.optionals cfg.discard [ "discard=async" ];
        };
        "/boot" = {
          device = cfg.partitions.boot;
          fsType = "vfat";
        };
        "/home" = {
          device = decryptPath;
          fsType = "btrfs";
          options = [
            "subvol=@home"
            "compress=zstd"
          ] ++ lib.optionals cfg.discard [ "discard=async" ];
        };
        "/var/log" = {
          device = decryptPath;
          fsType = "btrfs";
          options = [
            "subvol=@log"
            "compress=zstd"
          ] ++ lib.optionals cfg.discard [ "discard=async" ];
        };
        "/nix" = {
          device = decryptPath;
          fsType = "btrfs";
          options = [
            "subvol=@nix"
            "compress=zstd"
            "noatime"
          ] ++ lib.optionals cfg.discard [ "discard=async" ];
        };
      }
      // lib.optionalAttrs cfg.swapFile.enable {
        "/swap" = {
          device = decryptPath;
          fsType = "btrfs";
          options = [
            "subvol=@swap"
            "noatime"
          ] ++ lib.optionals cfg.discard [ "discard=async" ];
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
