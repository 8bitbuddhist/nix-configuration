{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.host.role;
in
{
  options = {
    host.role = lib.mkOption {
      type = lib.types.enum [
        "server"
        "workstation"
      ];
    };
  };

  config = lib.mkMerge [
    # Servers
    (lib.mkIf (cfg == "server") {
      host.apps.tmux.enable = true;
      environment.systemPackages = with pkgs; [
        htop
        mdadm
      ];
    })

    # Workstations
    (lib.mkIf (cfg == "workstation") {
      host.ui = {
        audio.enable = true;
        bluetooth.enable = true;
        gnome.enable = true;
        flatpak.enable = true;
      };

      boot = {
        # Enable Plymouth
        plymouth.enable = true;
        plymouth.theme = "bgrt";

        # Increase minimum log level. This removes ACPI errors from the boot screen.
        consoleLogLevel = 1;

        # Add kernel parameters
        kernelParams = [
          "quiet"
          "splash"
        ];
        initrd.verbose = false;
      };
    })
  ];
}
