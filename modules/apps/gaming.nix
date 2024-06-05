{
  config,
  lib,
  pkgs,
  ...
}:

# Gaming-related settings
let
  cfg = config.host.apps.gaming;
  reset-controllers-script = pkgs.writeShellScriptBin "reset-controllers" ''
    #!/usr/bin/env bash
    sudo rmmod hid_xpadneo && sudo modprobe hid_xpadneo
    sudo systemctl restart bluetooth.service
  '';
in
with lib;
{
  options = {
    host.apps.gaming.enable = mkEnableOption (mdDoc "Enables gaming features");
  };

  config = mkIf cfg.enable {
    host.ui.flatpak.enable = true;
    services.flatpak.packages = [
      "gg.minion.Minion"
      "com.valvesoftware.Steam"
      "org.firestormviewer.FirestormViewer"
    ];

    # Enable Xbox controller driver (XPadNeo)
    hardware.xpadneo.enable = true;

    # Add script to restart xpadneo in case of issues
    environment.systemPackages = [ reset-controllers-script ];
  };
}
