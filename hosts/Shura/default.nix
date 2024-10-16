{ config, pkgs, ... }:
let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.05";
  hostName = "Shura";

  # Copy bluetooth device configs
  shure-aonic-bluetooth = pkgs.writeText "info" (
    builtins.readFile ./bluetooth/shure-aonic-bluetooth-params
  );
  mano-touchpad-bluetooth = pkgs.writeText "info" (
    builtins.readFile ./bluetooth/mano-touchpad-bluetooth-params
  );
  vitrix-pdp-pro-bluetooth = pkgs.writeText "info" (
    builtins.readFile ./bluetooth/vitrix-pdp-pro-params
  );

  # Use gremlin user's monitor configuration for GDM (desktop monitor primary). See https://discourse.nixos.org/t/gdm-monitor-configuration/6356/4
  monitorsXmlContent = builtins.readFile ./monitors.xml;
  monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  custom-fonts.Freight-Pro.enable = true;

  aux.system = {
    apps = {
      development.enable = true;
      dj.enable = true;
      gaming.enable = true;
      media.enable = true;
      office.enable = true;
      recording.enable = true;
      social.enable = true;
      writing.enable = true;
    };

    # Configure the bootloader.
    bootloader = {
      enable = true;
      secureboot.enable = true;
      tpm2.enable = true;
    };

    # Change the default text editor. Options are "emacs", "nano", or "vim".
    editor = "nano";

    # Enable GPU support.
    gpu.amd.enable = true;

    packages = with pkgs; [
      boinc # Boinc client
      keepassxc # Use native instead of Flatpak due to weird performance issues
    ];

    # Enable support for primary RAID array (just in case)
    raid.storage.enable = true;

    # Keep old generations for two weeks.
    retentionPeriod = "14d";

    services = {
      # Run daily automatic updates.
      autoUpgrade = {
        enable = true;
        configDir = config.secrets.nixConfigFolder;
        onCalendar = "daily";
        user = config.users.users.aires.name;
      };
      netdata = {
        # FIXME: Disabled until I get Nginx configured to provide a streaming endpoint
        enable = false;
        type = "child";
        url = config.secrets.services.netdata.url;
        auth.apiKey = config.secrets.services.netdata.apiKey;
      };
      # Install virtual machine management tools
      virtualization = {
        enable = true;
        host = {
          user = "aires";
          vmBuilds = {
            enable = true;
            cores = 4;
            ram = 4096;
          };
        };
      };
    };
    ui = {
      flatpak = {
        # Enable Flatpak support.
        enable = true;

        # Define Flatpak packages to install.
        packages = [
          "com.github.tchx84.Flatseal"
          "com.github.wwmm.easyeffects"
          "md.obsidian.Obsidian"
          "org.mozilla.firefox"
        ];

        useBindFS = true;
      };
      desktops.gnome = {
        enable = true;
        experimental = {
          fractionalScaling.enable = true;
          vrr.enable = true;
        };
      };
    };
    users = {
      aires = {
        enable = true;
        services.syncthing.enable = true;
      };
      gremlin = {
        enable = true;
        services.syncthing.enable = true;
      };
    };
  };

  # Move files into target system
  systemd.tmpfiles.rules = [
    # Use gremlin user's monitor config for GDM (defined above)
    "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"

    # Install Bluetooth device profiles
    "d /var/lib/bluetooth/AC:50:DE:9F:AB:88/ 0700 root root" # First, make sure the directory exists
    "L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/00:0E:DD:72:2F:0C/info - - - - ${shure-aonic-bluetooth}"
    "L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/F8:5D:3C:7D:9A:00/info - - - - ${mano-touchpad-bluetooth}"
    "L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/00:34:30:47:37:AB/info - - - - ${vitrix-pdp-pro-bluetooth}"
  ];

}
