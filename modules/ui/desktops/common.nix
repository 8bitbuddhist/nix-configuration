# Common desktop environment modules
{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.aux.system.ui.desktops;
in
{
  options = {
    aux.system.ui.desktops = {
      enable = lib.mkEnableOption "Enables base desktop environment support.";
      xkb = lib.mkOption {
        description = "The keyboard layout to use by default. Defaults to us.";
        type = lib.types.attrs;
        default = {
          layout = "us";
          variant = "";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    aux.system = {
      bluetooth = {
        enable = true;
        experimental.enable = true;
      };
      packages = with pkgs; [
        qjournalctl # Journalctl frontend
      ];
      ui.audio.enable = true;
    };

    boot = {
      # Enable Plymouth for graphical bootsplash.
      plymouth = {
        enable = true;
        theme = "bgrt";
      };

      # Add kernel parameters
      kernelParams = [
        "quiet"
        "splash"
      ];

      # Increase minimum log level. This removes ACPI errors from the boot screen.
      consoleLogLevel = 1;
    };

    # Manage fonts
    fonts = {
      # Install extra fonts
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-emoji
        liberation_ttf
        fira-code
        fira-code-nerdfont
        fira-code-symbols
        fira
        roboto-slab
      ];

      # Enable font dir for use with Flatpak. See https://wiki.nixos.org/wiki/Fonts#Flatpak_applications_can.27t_find_system_fonts
      fontDir.enable = true;
    };

    services = {
      # Configure the xserver
      xserver = {
        # Enable the X11 windowing system.
        enable = true;

        # Configure keymap in X11
        xkb = config.aux.system.ui.desktops.xkb;
      };

      # Enable touchpad support (enabled by default in most desktop managers, buuuut just in case).
      libinput.enable = true;

      # Enable printing support, but disable browsed per https://discourse.nixos.org/t/cups-cups-filters-and-libppd-security-issues/52780.
      printing = {
        enable = true;
        browsed.enable = false;
      };
    };

    # Support for AppImage files
    programs.appimage = {
      enable = true;
      binfmt = true;
    };

    environment.sessionVariables = {
      # Tell Electron apps that they can use Wayland
      NIXOS_OZONE_WL = "1";
      # Install full GStreamer capabilities.
      # References: 
      #   https://wiki.nixos.org/wiki/GStreamer
      #   https://github.com/NixOS/nixpkgs/issues/195936
      GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
        with pkgs.gst_all_1;
        [
          gstreamer
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
          gst-vaapi
        ]
      );
    };
  };
}
