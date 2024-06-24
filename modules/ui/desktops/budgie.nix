# Enables the Budgie desktop environment.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.ui.desktops.budgie;
in
{
  options = {
    aux.system.ui.desktops.budgie.enable = lib.mkEnableOption (
      lib.mdDoc "Enables the Budgie desktop environment."
    );
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.desktops.enable = true;

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
