# Enables virtualization via QEMU/KVM
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.host.services.virtualization;
in
{
  options = {
    host.services.virtualization = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables virtualization hosting tools on this host.");
      user = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The default user to add as a KVM admin.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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

    users.users.${cfg.user}.extraGroups = [ "libvirtd" ];

    environment.systemPackages = with pkgs; [
      spice
      spice-gtk
      spice-protocol
      virt-viewer
    ];
    programs.virt-manager.enable = true;

    home-manager.users.${cfg.user} = {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    };
  };
}
