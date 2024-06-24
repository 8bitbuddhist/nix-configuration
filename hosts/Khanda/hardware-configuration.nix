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
      # Enable systemd for TPM auto-unlocking
      systemd.enable = true;

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

    kernel.sysctl = {
      # Try to reduce swappiness - Khanda hates paging, even to NVMe storage
      "vm.swappiness" = 20;
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
      options = [ "subvol=@,compress=zstd,nodiscard" ];
    };

    "/boot" = {
      device = "/dev/disk/by-uuid/DD2A-9C83";
      fsType = "vfat";
    };
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/8c2519d9-3e47-4aa1-908d-98b1aa8b909d"; } ];

  networking = {
    useDHCP = lib.mkDefault true;
    hostName = "Khanda";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    # Enable camera driver
    # NOTE: Currently results in a build failure. For updates, see https://github.com/NixOS/nixpkgs/issues/303067
    /*
      ipu6 = {
        enable = true;
        platform = "ipu6ep";
      };
    */
  };

  # Install/configure additional drivers, particularly for touch
  environment.systemPackages = with pkgs; [ libwacom-surface ];

  # NOTE: Use a default kernel to skip full kernel rebuilds
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
}
