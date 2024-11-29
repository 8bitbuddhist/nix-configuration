# Enables the Gnome desktop environment.
{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.aux.system.ui.desktops.gnome;
in
{

  options = {
    aux.system.ui.desktops.gnome = {
      enable = lib.mkEnableOption "Enables the Gnome Desktop Environment.";
    };
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.desktops.enable = true;

    # Enable Gnome
    services = {
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
        "org.gnome.gitg"
        "org.gnome.Loupe" # Gnome's fancy new image viewer
        "org.gnome.Music"
        "org.gnome.seahorse.Application"
        "org.gnome.Shotwell"
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

    # Make sure the keyring is properly unlocked at startup.
    # See https://discourse.nixos.org/t/login-keyring-did-not-get-unlocked-hyprland/40869/8
    security.pam.services.gdm.enableGnomeKeyring = true;
  };
}
