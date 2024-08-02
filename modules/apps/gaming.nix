{
  config,
  lib,
  pkgs,
  ...
}:

# Gaming-related settings
let
  cfg = config.aux.system.apps.gaming;
  reset-controllers-script = pkgs.writeShellScriptBin "reset-controllers" ''
    #!/usr/bin/env bash
    sudo rmmod hid_xpadneo && sudo modprobe hid_xpadneo
    sudo systemctl restart bluetooth.service
  '';
in
{
  options = {
    aux.system.apps.gaming.enable = lib.mkEnableOption "Enables gaming features";
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.flatpak = {
      enable = true;
      packages = [
        "gg.minion.Minion"
        "com.valvesoftware.Steam"
        "org.firestormviewer.FirestormViewer"
      ];
    };

    # Enable Xbox controller driver (XPadNeo)
    hardware.xpadneo.enable = true;

    # Add script to restart xpadneo in case of issues
    aux.system.packages = [ reset-controllers-script ];

    # Enable GameMode
    programs.gamemode.enable = true;
  };
}
