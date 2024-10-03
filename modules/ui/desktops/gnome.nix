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
      experimental = {
        fractionalScaling.enable = lib.mkEnableOption "Enables fractional scaling.";
        tripleBuffering.enable = lib.mkEnableOption "Enables dynamic triple buffering for xwayland applications.";
        vrr.enable = lib.mkEnableOption "Enables variable refresh rate (VRR).";
      };
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

          # Enable experimental features
          extraGSettingsOverrides = ''
            [org.gnome.mutter]
            experimental-features = ${
              lib.strings.concatStrings [
                "[ "
                (lib.mkIf cfg.experimental.fractionalScaling.enable "'scale-monitor-framebuffer', ").content
                (lib.mkIf cfg.experimental.vrr.enable "'variable-refresh-rate'").content
                " ]"
              ]
            }
          '';
          extraGSettingsOverridePackages = lib.mkIf (
            cfg.experimental.fractionalScaling.enable || cfg.experimental.vrr.enable
          ) [ pkgs.gnome.mutter ];
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
      gnome.excludePackages =
        (with pkgs; [
          gnome-photos
          gnome-tour
          gnomeExtensions.extension-list
          gedit # text editor
        ])
        ++ (with pkgs.gnome; [
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
        ]);

      # Install additional packages
      systemPackages = with pkgs; [
        # Gnome tweak tools
        gnome.gnome-tweaks
        # Gnome extensions
        gnomeExtensions.alphabetical-app-grid
        gnomeExtensions.appindicator
        gnomeExtensions.dash-to-panel
        # Themeing
        gnome.gnome-themes-extra
        papirus-icon-theme
        qogir-icon-theme
      ];
    };

    # Gnome UI integration for KDE apps
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    nixpkgs.overlays = lib.mkIf cfg.experimental.tripleBuffering.enable [
      (final: prev: {
        gnome = prev.gnome.overrideScope (
          gnomeFinal: gnomePrev: {
            mutter = gnomePrev.mutter.overrideAttrs (old: {
              src = inputs.gnome-triplebuffering;
            });
          }
        );
      })
    ];
  };
}
