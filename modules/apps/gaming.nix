{
  config,
  lib,
  pkgs,
  ...
}:

# Gaming-related settings
let
  cfg = config.host.apps.gaming;
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
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
      kernelModules = [ "hid_xpadneo" ];
    };
  };
}
