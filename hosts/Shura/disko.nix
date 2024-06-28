{ lib, config, ... }:
let
  cfg = config.disko;

  standardMountOpts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  options = {
    disko = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables Disko for disk & partition management.");
      primaryDisk = lib.mkOption {
        type = lib.types.attrs;
        description = "The disk to format using Disko.";
        default = {
          name = "nvme0n1";
          id = "";
        };
      };
      enableTPM = lib.mkOption {
        type = lib.types.bool;
        description = "Enables TPM2 support.";
        default = true;
      };
      swapFile = {
        enable = lib.mkEnableOption (lib.mdDoc "Enables the creation of swap files.");
        size = lib.mkOption {
          type = lib.types.str;
          description = "The size of the swap file to create (defaults to 8G, or 8 gigabytes).";
          default = "8G";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Disk management
    disko.enableConfig = false;
    disko.devices = {
      disk = {
        main = {
          type = "disk";
          device = "/dev/disk/by-id/${cfg.primaryDisk.id}";
          content = {
            type = "gpt";
            partitions = {
              ESP = {
                priority = 1;
                name = "ESP";
                label = "boot";
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                };
              };
              luks = {
                size = "100%";
                label = "nixos";
                content = {
                  type = "luks";
                  name = "cryptroot";
                  settings = {
                    allowDiscards = true;
                    crypttabExtraOpts = lib.mkIf cfg.enableTPM [ "tpm2-device=auto" ];
                  };
                  content = {
                    type = "btrfs";
                    extraArgs = [ "-f" ]; # Override existing partitions.
                    # Unless otherwise specified, the subvolume name equals the mount name.
                    subvolumes = {
                      "/root" = {
                        mountpoint = "/";
                        mountOptions = standardMountOpts;
                      };
                      "/home" = {
                        mountOptions = standardMountOpts;
                      };
                      "/nix" = {
                        mountOptions = standardMountOpts;
                      };
                      "/swap" = lib.mkIf cfg.swapFile.enable {
                        mountpoint = "/.swap";
                        swap.swapfile.size = cfg.swapFile.size;
                      };
                      "/log" = {
                        mountpoint = "/var/log";
                        mountOptions = standardMountOpts;
                      };
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
