# Enables the Budgie desktop environment.
{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.ui.desktops.budgie;
in
{
  options = {
    ${namespace}.ui.desktops.budgie.enable =
      lib.mkEnableOption "Enables the Budgie desktop environment.";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.ui.desktops.enable = true;

    services.xserver = {
      enable = true;
      desktopManager.budgie.enable = true;
      displayManager.lightdm.enable = lib.mkIf (
        !(
          config.services.xserver.displayManager.gdm.enable
          || config.services.xserver.displayManager.sddm.enable
        )
      ) true;
    };
  };
}
