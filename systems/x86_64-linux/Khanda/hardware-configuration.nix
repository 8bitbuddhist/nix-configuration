# Surface Pro 9
{
  config,
  lib,
  pkgs,
  modulesPath,
  namespace,
  ...
}:
let
  bootUUID = "6579-B6CB"; # The UUID of the boot partition.
  luksUUID = "9936b186-96a5-4e43-9aba-0e0a0eb587df"; # The UUID of the locked LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    # NOTE: Uncomment to use a default kernel and skip full kernel rebuilds
    #kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    kernelModules = [ "kvm-intel" ];

    # NOTE: Loading the camera driver results in a kernel panic on 6.10 kernels. See https://github.com/linux-surface/linux-surface/issues/1516
    blacklistedKernelModules = [
      "intel-ipu6"
      "intel-ipu6-isys"
    ];

    # Enable antenna aggregation
    extraModprobeConfig = ''
      options iwlwifi 11n_disable=8
    '';

    initrd.kernelModules = [
      "kvm-intel"
      "surface_aggregator"
      "surface_aggregator_registry"
      "surface_aggregator_hub"
      "surface_hid_core"
      "surface_hid"
      "hid_multitouch"
      "8250_dw"
      "intel_lpss"
      "intel_lpss_pci"
      "xhci_pci"
      "thunderbolt"
      "nvme"
      "usb_storage"
      "sd_mod"
      "surface_kbd"
      "pinctrl_tigerlake"
    ];

    kernelParams = [
      "pci=hpiosize=0" # Prevent ACPI interrupt storm. See https://github.com/linux-surface/linux-surface/wiki/Surface-Pro-9#acpi-interrupt-storm
      "i915.perf_stream_paranoid=0" # Enable performance support. See https://wiki.archlinux.org/title/Intel_graphics#Enable_performance_support and https://github.com/NixOS/nixos-hardware/issues/1246
    ];
  };

  # Configure the main filesystem.
  ${namespace}.filesystem = {
    enable = true;
    partitions = {
      boot = "/dev/disk/by-uuid/${bootUUID}";
      luks = "/dev/disk/by-uuid/${luksUUID}";
    };
    swapFile = {
      enable = true;
      size = 16384;
    };
  };

  hardware = {
    cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
    /*
      FIXME: temporarily disable due to conflict with kernel 6.12+

      ipu6 = {
        enable = true;
        platform = "ipu6ep";
      };
    */
  };

  # Limit the number of cores Nix can use
  nix.settings.cores = 8;

  # Install/configure additional drivers, particularly for touch
  environment.systemPackages = with pkgs; [ libwacom-surface ];
}
