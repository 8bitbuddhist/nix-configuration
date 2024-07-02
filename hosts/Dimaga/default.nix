{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.11";
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;

  ###*** Configure your system below this line. ***###
  # Set your time zone.
  #   To see all available timezones, run `timedatectl list-timezones`.
  time.timeZone = "America/New_York";

  # Configure the system.
  aux.system = {
    # Enable to allow unfree (e.g. closed source) packages.
    # Some settings may override this (e.g. enabling Nvidia GPU support).
    # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
    allowUnfree = true;

    apps = {
      development.enable = true;
      #media.enable = true;
      #office.enable = true;
      #recording.enable = true;
      #social.enable = true;
      #writing.enable = true;
    };

    # Enable Secure Boot support.
    bootloader = {
      enable = true;
      #secureboot.enable = true;
      tpm2.enable = true;
    };

    # Change the default text editor. Options are "emacs", "nano", or "vim".
    editor = "nano";

    # Enable GPU support.
    gpu = {
      intel.enable = true;
      nvidia = {
        enable = true;
        hybrid = {
          enable = true;
          busIDs.nvidia = "PCI:3:0:0";
          busIDs.intel = "PCI:0:2:0";
        };
      };
    };

    # Change how long old generations are kept for.
    retentionPeriod = "14d";

    services = {
      autoUpgrade = {
        enable = true;
        configDir = config.secrets.nixConfigFolder;
        onCalendar = "daily";
        user = config.users.users.aires.name;
      };
      virtualization.enable = true;
    };

    ui = {
      desktops.gnome = {
        enable = true;
        tripleBuffering.enable = true;
      };
      flatpak = {
        # Enable Flatpak support.
        enable = true;

        # Define Flatpak packages to install.
        packages = [
          "com.github.tchx84.Flatseal"
          "com.github.wwmm.easyeffects"
          "md.obsidian.Obsidian"
          "org.keepassxc.KeePassXC"
          "org.mozilla.firefox"
        ];
      };
    };

    users.aires = {
      enable = true;
      services = {
        syncthing = {
          enable = true;
          autostart = true;
          enableTray = false;
        };
      };
    };
  };
}
