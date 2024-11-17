{ config, ... }:

let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.05";
  hostName = "Khanda";
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  ###*** Configure your system below this line. ***###
  # Configure the system.
  aux.system = {
    # Enable to allow unfree (e.g. closed source) packages.
    # Some settings may override this (e.g. enabling Nvidia GPU support).
    # https://nixos.org/manual/nixpkgs/stable/#sec-allow-unfree
    allowUnfree = true;

    apps = {
      development.enable = true;
      media.enable = true;
      office.enable = true;
      recording.enable = true;
      social.enable = true;
      writing.enable = true;
    };

    # Enable Secure Boot support.
    bootloader = {
      enable = true;
      secureboot.enable = true;
      tpm2.enable = true;
    };

    # Change the default text editor. Options are "emacs", "nano", or "vim".
    editor = "nano";

    # Enable GPU support.
    gpu.intel.enable = true;

    # Enable support for primary RAID array (just in case)
    raid.storage.enable = true;

    # Change how long old generations are kept for.
    retentionPeriod = "14d";

    services = {
      autoUpgrade = {
        enable = true;
        configDir = config.secrets.nixConfigFolder;
        extraFlags = "--build-host hevana";
        onCalendar = "weekly";
        user = config.users.users.aires.name;
      };
      virtualization.enable = true;
    };

    ui = {
      desktops.gnome = {
        enable = true;
        experimental.enable = false;
      };
      flatpak = {
        # Enable Flatpak support.
        enable = true;

        # Define Flatpak packages to install.
        packages = [
          "com.github.tchx84.Flatseal"
          "com.github.wwmm.easyeffects"
          "io.github.elevenhsoft.WebApps"
          "md.obsidian.Obsidian"
          "org.keepassxc.KeePassXC"
          "org.mozilla.firefox"
        ];

        useBindFS = true;
      };
    };

    users.aires = {
      enable = true;
      services.syncthing = {
        enable = true;
        enableTray = true;
        web = {
          enable = true;
          port = 8080;
        };
      };
    };
  };
}
