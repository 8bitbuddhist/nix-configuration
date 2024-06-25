{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.05";
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
      media.enable = true;
      office.enable = true;
      recording.enable = true;
      social.enable = true;
      writing = {
        enable = true;
        languagetool.enable = false;
      };
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

    # Change how long old generations are kept for.
    retentionPeriod = "14d";

    services = {
      autoUpgrade.enable = false;
      virtualization.enable = true;
    };

    ui = {
      desktops.gnome.enable = true;
      flatpak = {
        # Enable Flatpak support.
        enable = true;

        # Define Flatpak packages to install.
        packages = [
          "com.github.tchx84.Flatseal"
          "com.github.wwmm.easyeffects"
          "md.obsidian.Obsidian"
          "net.waterfox.waterfox"
          "org.keepassxc.KeePassXC"
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

  # Build remotely
  nix.distributedBuilds = true;

  # Limit the number of cores Nix can use
  nix.settings.cores = 10;

  # Configure the virtual machine created by nixos-rebuild build-vm
  virtualisation.vmVariant.virtualisation = {
    memorySize = 2048;
    cores = 2;
  };
}
