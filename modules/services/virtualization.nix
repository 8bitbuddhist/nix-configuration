# Enables virtualization via QEMU/KVM
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.services.virtualization;
in
{
  options = {
    aux.system.services.virtualization = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables virtualization tools on this host.");
      host = {
        enable = lib.mkEnableOption (lib.mdDoc "Enables virtual machine hosting.");
        user = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "The default user to add as a KVM admin.";
        };
        vmBuilds = {
          enable = lib.mkEnableOption (lib.mdDoc "Enables builds via `nixos-rebuild build-vm` on this host.");
          cores = lib.mkOption {
            type = lib.types.int;
            description = "How many cores to assign to `nixos-rebuild build-vm` builds. Defaults to 2.";
            default = 2;
          };
          ram = lib.mkOption {
            type = lib.types.int;
            description = "How much RAM (in MB) to assign to `nixos-rebuild build-vm` builds. Defaults to 2GB.";
            default = 2048;
          };
        };
      };

    };
  };

  config = lib.mkMerge [
    { programs.virt-manager.enable = cfg.enable; }
    (lib.mkIf (cfg.host.enable || cfg.host.vmBuilds.enable) {
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            swtpm.enable = true;
            ovmf.enable = true;
            ovmf.packages = [ pkgs.OVMFFull.fd ];
          };
        };
        spiceUSBRedirection.enable = true;
      };

      users.users.${cfg.host.user}.extraGroups = [ "libvirtd" ];

      environment.systemPackages = with pkgs; [
        spice
        spice-gtk
        spice-protocol
      ];

      # Allow the default bridge interface to access the network
      networking.firewall.trustedInterfaces = [ "virbr0" ];
    })
    (lib.mkIf cfg.host.vmBuilds.enable {
      virtualisation.vmVariant.virtualisation = {
        memorySize = cfg.host.vmBuilds.ram;
        cores = cfg.host.vmBuilds.cores;
      };
    })
  ];
}
