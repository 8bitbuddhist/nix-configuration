{ lib, config, ... }:
let
  cfg = config.aux.system.disko;

  standardMountOpts = [
    "compress=zstd"
    "noatime"
  ];
in
{
  options = {
    aux.system.disko = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables Disko for disk & partition management.");
      primaryDiskID = lib.mkOption {
        type = lib.types.str;
        description = "The ID of the disk to manage using Disko. If possible, use the World Wide Name (WWN), e.g `/dev/disk/by-id/nvme-eui.*`";
        default = "";
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
    # Check for blank values
      assertions = [
        {
          assertion = (cfg.primaryDiskID != "");
          message = "aux.system.disko.primaryDiskID is not set. Please enter a valid disk ID.";
        }
      ];
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
                    crypttabExtraOpts = lib.mkIf config.aux.system.bootloader.tpm2.enable [ "tpm2-device=auto" ];
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
