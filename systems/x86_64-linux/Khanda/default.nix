{
  config,
  options,
  namespace,
  ...
}:

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
  ${namespace} = {
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

    powerManagement.enable = true;

    # Enable support for primary RAID array (just in case)
    raid.storage.enable = true;

    services = {
      autoUpgrade = {
        enable = true;
        configDir = config.${namespace}.secrets.nixConfigFolder;
        extraFlags = "--build-host hevana";
        onCalendar = "weekly";
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
      virtualization.enable = true;
    };

    ui = {
      desktops.gnome.enable = true;
      flatpak = {
        # Enable Flatpak support.
        enable = true;

        # Define extra Flatpak packages to install.
        packages = options.${namespace}.ui.flatpak.packages.default ++ [
          "org.keepassxc.KeePassXC"
        ];

        useBindFS = true;
      };
    };

    users.aires.enable = true;
  };
}
