# Enables the Hyprland desktop environment.
{ config, lib, ... }:
let
  cfg = config.aux.system.ui.desktops.hyprland;
in
{
  options = {
    aux.system.ui.desktops.hyprland.enable = lib.mkEnableOption (
      lib.mdDoc "Enables the Hyprland desktop environment."
    );
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.desktops.enable = true;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    # Optional: hint Electron apps to use Wayland:
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
