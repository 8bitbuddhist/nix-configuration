# Enables the Hyprland desktop environment.
{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.ui.desktops.hyprland;
in
{
  options = {
    ${namespace}.ui.desktops.hyprland.enable =
      lib.mkEnableOption "Enables the Hyprland desktop environment.";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.ui.desktops.enable = true;

    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    # Optional: hint Electron apps to use Wayland:
    environment.sessionVariables.NIXOS_OZONE_WL = "1";
  };
}
