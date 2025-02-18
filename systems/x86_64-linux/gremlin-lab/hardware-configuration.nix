# MSI Prestge 15
{
  config,
  lib,
  modulesPath,
  namespace,
  ...
}:

let
  bootUUID = "BB32-0650"; # The UUID of the boot partition.
  luksUUID = "688c96d9-61a0-4c26-9504-771f6c489c9c"; # The UUID of the locked LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    # Enable antenna aggregation
    extraModprobeConfig = ''
      options iwlwifi 11n_disable=8
    '';

    initrd.availableKernelModules = [
      "xhci_pci"
      "nvme"
      "usb_storage"
      "sd_mod"
      "sdhci_pci"
    ];
    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];

    # Enable support for building ARM64 packages
    binfmt.emulatedSystems = [ "aarch64-linux" ];
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

  # Disable suspend
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };
  services = {
    xserver.displayManager.gdm.autoSuspend =
      lib.mkIf config.${namespace}.ui.desktops.gnome.enable
        false;
    logind = {
      lidSwitch = "lock";
      lidSwitchDocked = "lock";
    };
  };
  services.upower.ignoreLid = true;

  # Enable CPU microde updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
