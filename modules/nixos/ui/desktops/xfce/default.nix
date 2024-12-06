# Enables the XFCE desktop environment.
{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.ui.desktops.xfce;
in
{
  options = {
    ${namespace}.ui.desktops.xfce.enable = lib.mkEnableOption "Enables the XFCE desktop environment.";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.ui.desktops.enable = true;

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
