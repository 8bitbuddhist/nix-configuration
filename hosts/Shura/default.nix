{ config, pkgs, ... }:
let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.05";
  hostName = "Shura";

  # Use gremlin user's monitor configuration for GDM (desktop monitor primary). See https://discourse.nixos.org/t/gdm-monitor-configuration/6356/4
  monitorsXmlContent = builtins.readFile ./monitors.xml;
  monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  custom-fonts.Freight-Pro.enable = config.aux.system.users.gremlin.enable;

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

    bluetooth.adapter = "AC:50:DE:9F:AB:88";

    # Change the default text editor. Options are "emacs", "nano", or "vim".
    editor = "nano";

    # Enable GPU support.
    gpu.amd.enable = true;

    packages = with pkgs; [
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
        operation = "boot";
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
          "io.github.elevenhsoft.WebApps"
          "md.obsidian.Obsidian"
          "org.mozilla.firefox"
        ];

        useBindFS = true;
      };
      desktops.gnome.enable = true;
    };
    users = {
      aires = {
        enable = true;
        services.syncthing = {
          enable = true;
          enableTray = true;
          web.enable = true;
        };
      };
      gremlin.enable = true;
    };
  };

  # Move files into target system
  systemd.tmpfiles.rules = [
    # Use gremlin user's monitor config for GDM (defined above)
    "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"
  ];

}
