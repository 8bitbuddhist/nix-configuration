# Surface Pro 9
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [
        "surface_aggregator"
        "surface_aggregator_registry"
        "surface_aggregator_hub"
        "surface_hid_core"
        "hid_multitouch"
        "8250_dw"
        "intel_lpss"
        "intel_lpss_pci"
        "tpm_crb"
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
        "surface_kbd"
        "pinctrl_tigerlake"
      ];
      kernelModules = [
        "tpm_crb"
        "surface_aggregator"
        "surface_aggregator_registry"
        "surface_aggregator_hub"
        "surface_hid_core"
        "surface_hid"
        "hid_multitouch"
        "8250_dw"
        "intel_lpss"
        "intel_lpss_pci"
        "surface_kbd"
        "pinctrl_tigerlake"
      ];

      luks.devices."luks-bd1fe396-6740-4e7d-af2c-26ca9a3031f1" = {
        device = "/dev/disk/by-uuid/bd1fe396-6740-4e7d-af2c-26ca9a3031f1";
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      };
    };

    kernelModules = [
      "kvm-intel"
      "tpm_crb"
      "surface_aggregator"
      "surface_aggregator_registry"
      "surface_aggregator_hub"
      "surface_hid_core"
      "surface_hid"
      "hid_multitouch"
      "8250_dw"
      "intel_lpss"
      "intel_lpss_pci"
      "surface_kbd"
      "pinctrl_tigerlake"
    ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b34afd29-94ff-421b-bb96-8497951abf58";
      fsType = "btrfs";
      options = [ "subvol=@,compress=zstd" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/DD2A-9C83";
      fsType = "vfat";
    };
  };

  # TODO: Disable once DIsko is up and running
  swapDevices = [ { device = "/dev/disk/by-uuid/8c2519d9-3e47-4aa1-908d-98b1aa8b909d"; } ];

  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "Khanda";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Install/configure additional drivers, particularly for touch
  environment.systemPackages = with pkgs; [ libwacom-surface ];
  microsoft-surface = {
    ipts.enable = true;
    surface-control.enable = true;
  };

  # NOTE: Use a default kernel to skip full kernel rebuilds
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

  # Disk management
  disko.enableConfig = false; # Disable while testing
  disko.devices = {
    disk = {
      nvme0n1 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-MZ9L4256HCJQ-00BMV-SAMSUNG_S69VNE0X195093";
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
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "8G";
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
