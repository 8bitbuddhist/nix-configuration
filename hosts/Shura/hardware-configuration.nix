# Lenovo Legion Slim 7 Gen 7 AMD (16ARHA7)
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Configure the kernel.
  boot = {
    # First, install the latest Zen kernel
    kernelPackages = pkgs.linuxPackages_zen;

    # Hardware defaults detected by nixos-generate-configuration
    initrd = {
      # SystemD in the initrd is required for TPM auto-unlocking.
      # See https://discourse.nixos.org/t/full-disk-encryption-tpm2/29454/2
      # If the LUKS volume is recently created, run this command to bind it to the TPM:
      #	sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/<device>
      systemd.enable = true;

      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "usbhid"
        "usb_storage"
        "sd_mod"
        "rtsx_pci_sdmmc"
        "tpm_crb"
      ];
      kernelModules = [
        "amdgpu"
        "tpm_crb"
      ];
      luks.devices."luks-bcf67e34-339e-40b9-8ffd-bec8f7f55248" = {
        device = "/dev/disk/by-uuid/bcf67e34-339e-40b9-8ffd-bec8f7f55248";
        crypttabExtraOpts = [ "tpm2-device=auto" ]; # Enable TPM auto-unlocking
      };
    };

    kernelModules = [ "kvm-amd" ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
      fsType = "btrfs";
      options = [ "subvol=@,compress=zstd" ];
    };
    "/home" = {
      device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
      fsType = "btrfs";
      options = [ "subvol=@home,compress=zstd" ];
    };
    "/swap" = {
      device = "/dev/disk/by-uuid/b801fbea-4cb5-4255-bea9-a2ce77d1a1b7";
      fsType = "btrfs";
      options = [ "subvol=@swap" ];
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/AFCB-D880";
      fsType = "vfat";
    };
  };

  networking = {
    # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
    # (the default) this is the recommended approach. When using systemd-networkd it's
    # still possible to use this option, but it's recommended to use it in conjunction
    # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
    useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp4s0.useDHCP = lib.mkDefault true;

    # Set the hostname.
    hostName = "Shura";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Disk management
  disko.enableConfig = false; # Disable while testing
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "";
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
                  crypttabExtraOpts = ["tpm2-device=auto"];
                };
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # Override existing partition
                  # Subvolumes must set a mountpoint in order to be mounted,
                  # unless their parent is mounted
                  subvolumes = {
                    # Subvolume name is different from mountpoint
                    "/root" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/";
                    };
                    "/home" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/home";
                    };
                    "/nix" = {
                      mountOptions = [ "compress=zstd" "noatime" ];
                      mountpoint = "/nix";
                    };
                    "/swap" = {
                      mountpoint = "/.swap";
                      swap.swapfile.size = "16G";
                    };
                    "/log" = {
                      mountpoint = "/var/log";
                      mountOptions = ["compress=zstd" "noatime"];
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
