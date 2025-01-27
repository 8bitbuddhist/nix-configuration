{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

# Gaming-related settings
let
  cfg = config.${namespace}.apps.gaming;
  reset-controllers-script = pkgs.writeShellScriptBin "reset-controllers" ''
    #!/usr/bin/env bash
    sudo rmmod hid_xpadneo && sudo modprobe hid_xpadneo
    sudo systemctl restart bluetooth.service
  '';
in
{
  options = {
    ${namespace}.apps.gaming.enable = lib.mkEnableOption "Enables gaming features";
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      # Add script to restart xpadneo in case of issues
      packages = [ reset-controllers-script ];

      ui.flatpak = {
        enable = true;
        packages = [
          "gg.minion.Minion"
          "com.valvesoftware.Steam"
          "com.valvesoftware.Steam.CompatibilityTool.Proton-GE"
          "io.github.lime3ds.Lime3DS"
          "org.firestormviewer.FirestormViewer"
        ];
      };
    };

    # Enable Xbox controller driver (XPadNeo)
    hardware.xpadneo.enable = true;

    # Enable GameMode
    programs.gamemode.enable = true;
  };
}
