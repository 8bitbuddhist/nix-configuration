# Enables the Gnome desktop environment.
{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.ui.desktops.gnome;
in
{

  options = {
    ${namespace}.ui.desktops.gnome = {
      enable = lib.mkEnableOption "Enables the Gnome Desktop Environment.";
      autologin = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Which user to automatically log in (leave empty to disable).";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.ui.desktops.enable = true;

    # This is a workaround for shells crashing on autologin.
    # See https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services = lib.mkIf (cfg.autologin != "") {
      "getty@tty1".enable = false;
      "autovt@tty1".enable = false;
    };

    # Enable Gnome
    services = {
      displayManager.autoLogin = lib.mkIf (cfg.autologin != "") {
        enable = true;
        user = cfg.autologin;
      };

      xserver = {
        # Remove default packages that came with the install
        excludePackages = [ pkgs.xterm ];

        # Enable Gnome
        desktopManager.gnome = {
          enable = true;
          # Enable native app scaling and VRR, and disable version checks for gnome extensions
          extraGSettingsOverrides = ''
            [org.gnome.mutter]
            experimental-features = [ 'scale-monitor-framebuffer', 'variable-refresh-rate' ]
            [org.gnome.shell]
            disable-extension-version-validation = true
          '';
          extraGSettingsOverridePackages = with pkgs; [
            mutter
            gnome-shell
          ];
        };
        displayManager.gdm.enable = true;
      };

      # Install Flatpaks
      flatpak.packages = [
        "com.github.finefindus.eyedropper"
        "com.mattjakeman.ExtensionManager"
        "org.bluesabre.MenuLibre"
        "org.gnome.baobab"
        "org.gnome.Calculator"
        "org.gnome.Characters"
        "org.gnome.Calendar"
        "org.gnome.Evince"
        "org.gnome.Evolution"
        "org.gnome.FileRoller"
        "org.gnome.Firmware"
        "org.gnome.Loupe"
        "org.gnome.Music"
        "org.gnome.seahorse.Application"
        "org.gnome.TextEditor"
        "org.gtk.Gtk3theme.Adwaita-dark"
      ];
    };

    environment = {
      # Remove default Gnome packages that came with the install, then install the ones I actually use
      gnome.excludePackages = (
        with pkgs;
        [
          gnome-photos
          gnome-tour
          gnomeExtensions.extension-list
          gedit # text editor
          gnome-music
          gnome-calendar
          epiphany # web browser
          geary # email reader
          evince # document viewer
          gnome-characters
          gnome-software
          totem # video player
          tali # poker game
          iagno # go game
          hitori # sudoku game
          atomix # puzzle game
        ]
      );

      # Install additional packages
      systemPackages = with pkgs; [
        # Gnome tweak tools
        gnome-tweaks
        # Themeing
        gnome-themes-extra
        papirus-icon-theme
        qogir-icon-theme
        # Gnome extensions
        gnomeExtensions.another-window-session-manager
        gnomeExtensions.appindicator
        gnomeExtensions.dash-to-panel
        gnomeExtensions.random-wallpaper
      ];
    };

    # Gnome UI integration for KDE apps
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };
  };
}
