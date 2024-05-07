{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}:
let
  inherit (config.host) role;
in
with lib;
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  config = mkIf (role == "workstation") {
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
      kernelParams = [ "quiet" ];
    };
  };
}
