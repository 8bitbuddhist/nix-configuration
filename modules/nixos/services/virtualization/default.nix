# Enables virtualization via QEMU/KVM
{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.virtualization;
in
{
  options = {
    ${namespace}.services.virtualization = {
      enable = lib.mkEnableOption "Enables virtualization tools on this host.";
      containers.enable = lib.mkEnableOption "Enables containers via Podman on this host.";
      host = {
        enable = lib.mkEnableOption "Enables virtual machine hosting.";
        vmBuilds = {
          enable = lib.mkEnableOption "Enables builds via `nixos-rebuild build-vm` on this host.";
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
    (lib.mkIf cfg.containers.enable {
      virtualisation.podman = {
        enable = true;
        autoPrune.enable = true;
      };
    })
    (lib.mkIf (cfg.host.enable || cfg.host.vmBuilds.enable) {
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu = {
            package = pkgs.qemu_kvm;
            swtpm.enable = true;
            ovmf = {
              enable = true;
              packages = [ pkgs.OVMFFull.fd ];
            };
          };
        };
        spiceUSBRedirection.enable = true;
      };

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
