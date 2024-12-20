# Template for setting a new host's hardware configuration
{
  modulesPath,
  namespace,
  ...
}:
let
  bootUUID = "ABCD-1234"; # The UUID of the boot partition.
  luksUUID = "1408f9cf-68b8-4063-b919-48edde3329a5"; # The UUID of the encrypted LUKS partition.
in
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Configure the kernel.
  boot = {
    # Run `nixos-generate-config --no-filesystems` to generate a baseline hardware configuration.
    initrd.availableKernelModules = [
      "nvme"
      "xhci_pci"
      "usbhid"
      "usb_storage"
      "sd_mod"
    ];

    kernelModules = [ ];
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
}
