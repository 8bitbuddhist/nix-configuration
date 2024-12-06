{ lib, osConfig, ... }:
{
  # NOTE: Allegedly prevents random Gnome crashes. But really, it just prevents me from logging in.
  # See https://www.reddit.com/r/archlinux/comments/1erbika/fyi_if_you_experience_crashes_on_gnome_on_amd/
  /*
    home.file.".config/environment.d/99-mutter-no-rt.conf".text = ''
      MUTTER_DEBUG_KMS_THREAD_TYPE=user;
    '';
  */

  # Additional Gnome configurations via home-manager.
  dconf.settings = lib.mkIf osConfig.aux.system.ui.desktops.gnome.enable {
    "org/gnome/mutter" = {
      edge-tiling = true;
      workspaces-only-on-primary = false;
    };

    "org/gnome/desktop/interface" = {
      # Configure fonts
      font-name = "Fira Sans Semi-Light 11";
      document-font-name = "Roboto Slab 11";
      monospace-font-name = "Liberation Mono 11";
      titlebar-font = "Fira Sans Semi-Bold 11";

      # Configure hinting
      font-hinting = "slight";
      font-antialiasing = "rgba";

      # Configure workspace
      enable-hot-corners = true;

      # Set icon theme
      icon-theme = "Papirus-Dark";

      # Set legacy application theme
      gtk-theme = "Adwaita-dark";
    };

    # Configure touchpad scroll & tap behavior
    "org/gnome/desktop/peripherals/touchpad" = {
      disable-while-typing = true;
      click-method = "fingers";
      tap-to-click = true;
      natural-scroll = true;
      two-finger-scrolling-enabled = true;
    };

    # Tweak window management
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu:minimize,maximize,close";
      resize-with-right-button = true;
      focus-mode = "click";
    };

    # Make alt-tab switch windows, not applications
    "org/gnome/desktop/wm/keybindings" = {
      switch-tab = [ ];
      switch-windows = [ "<Alt>Tab" ];
      switch-windows-backward = [ "<Shift><Alt>Tab" ];
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
    };
  };
}
