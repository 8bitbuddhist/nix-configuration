# Enables the KDE desktop environment.
{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.aux.system.ui.desktops.kde;
in
{
  options = {
    aux.system.ui.desktops.kde = {
      enable = lib.mkEnableOption "Enables the KDE Desktop Environment.";
      useX11 = lib.mkEnableOption "Uses X11 instead of Wayland.";
    };
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.desktops.enable = true;

    programs.dconf.enable = true;

    # Fix blank messages in KMail. See https://wiki.nixos.org/wiki/KDE#KMail_Renders_Blank_Messages
    environment.sessionVariables = {
      NIX_PROFILES = "${pkgs.lib.concatStringsSep " " (
        pkgs.lib.reverseList config.environment.profiles
      )}";
    };

    services = {
      displayManager.sddm.enable = true;
      desktopManager.plasma6.enable = true;

      xserver.displayManager = lib.mkIf cfg.useX11 {
        defaultSession = "plasmaX11";
        sddm.wayland.enable = lib.mkIf (
          !(
            config.services.xserver.displayManager.gdm.enable
            || config.services.xserver.displayManager.lightdm.enable
          )
        ) true;
      };
    };

    # Enable Gnome integration
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };
  };
}
