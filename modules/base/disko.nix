{ lib, config, ... }:
let
  cfg = config.host.base.disko;
in
{
  options = {
    host.base.disko = {
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
      swapFile = lib.mkOption {
        type = lib.types.attrs;
        description = "Swap file enabling and configuration.";
        default = {
          enable = true;
          size = "8G";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Disk management
    disko.enableConfig = true;
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
                    extraArgs = [ "-f" ]; # Override existing partition
                    subvolumes = {
                      "/root" = {
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                        mountpoint = "/";
                      };
                      "/home" = {
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                        mountpoint = "/home";
                      };
                      "/nix" = {
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
                        mountpoint = "/nix";
                      };
                      "/swap" = lib.mkIf cfg.swapFile.enable {
                        mountpoint = "/.swap";
                        swap.swapfile.size = cfg.swapFile.size;
                      };
                      "/log" = {
                        mountpoint = "/var/log";
                        mountOptions = [
                          "compress=zstd"
                          "noatime"
                        ];
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
