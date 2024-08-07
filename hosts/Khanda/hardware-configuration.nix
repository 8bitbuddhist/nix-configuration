# Surface Pro 9
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  bootUUID = "B2D7-96C3"; # The UUID of the boot partition.
  luksUUID = "f5ff391a-f2ef-4ac3-9ce8-9f5ed950b212"; # The UUID of the locked LUKS partition.
in
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
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
        "surface_kbd"
        "pinctrl_tigerlake"
      ];
      kernelModules = [
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
    };

    kernel.sysctl = {
      # Try to reduce swappiness - Khanda hates paging, even to NVMe storage
      "vm.swappiness" = 20;
    };

    kernelModules = [
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
      "surface_kbd"
      "pinctrl_tigerlake"
    ];
  };

  # Configure the main filesystem.
  aux.system.filesystem = {
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

  # Change I/O scheduler to BFQ to try and reduce stuttering under load.
  services.udev.extraRules = ''
    ACTION=="add|change", KERNEL=="nvme0*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
  '';

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

  # NOTE: Uncomment to use a default kernel and skip full kernel rebuilds
  # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;
}
