{
  config,
  lib,
  options,
  namespace,
  pkgs,
  ...
}:
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

  ${namespace} = {
    apps = {
      development.enable = true;
      gaming.enable = true;
      media = {
        enable = true;
        mixxx.enable = true;
      };
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
      keepassxc # Use native instead of Flatpak due to weird performance issues
    ];

    # Keep one week of generations.
    nix.retention = "7d";

    powerManagement.enable = true;

    services = {
      # Run daily automatic updates.
      autoUpgrade = {
        enable = true;
        configDir = config.${namespace}.secrets.nixConfigFolder;
        onCalendar = "daily";
        operation = "boot";
        user = config.users.users.aires.name;
      };
      syncthing = {
        enable = true;
        home = "/home/aires/.config/syncthing";
        tray.enable = true;
        user = "aires";
        web.enable = true;
      };
      tor = {
        enable = true;
        browser.enable = true;
        snowflake-proxy.enable = true;
      };
      virtualization = {
        enable = true;
        host = {
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
        enable = true;
        useBindFS = true;
        packages = options.${namespace}.ui.flatpak.packages.default;
      };
      desktops.gnome.enable = true;
    };
    users = {
      aires.enable = true;
      gremlin.enable = true;
    };
  };

  # Mount Gremlin's Notes folder
  fileSystems."/home/gremlin/Documents/Notes" = {
    device = "/home/aires/Documents/Notes";
    options = [ "bind" ];
  };

  # Install custom font
  fonts.packages = lib.mkIf config.${namespace}.users.gremlin.enable [
    pkgs.${namespace}.freight-pro
  ];

  systemd.tmpfiles.rules = [
    # Use gremlin user's monitor config for GDM (defined above)
    "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"
  ];

}
