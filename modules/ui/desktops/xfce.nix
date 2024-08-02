# Enables the XFCE desktop environment.
{ config, lib, ... }:
let
  cfg = config.aux.system.ui.desktops.xfce;
in
{
  options = {
    aux.system.ui.desktops.xfce.enable = lib.mkEnableOption (
      lib.mdDoc "Enables the XFCE desktop environment."
    );
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.desktops.enable = true;

    services.xserver = {
      enable = true;
      desktopManager = {
        xterm.enable = false;
        xfce.enable = true;
      };
      displayManager.defaultSession = "xfce";
    };
  };
}
