{
  config,
  pkgs,
  lib,
  namespace,
  ...
}:
let
  stateVersion = "24.05";
  hostName = "Pihole";

  # Script to unlock /sda and create /home symlinks, mount /swap, etc.
  start-pihole_script = pkgs.writeShellScriptBin "start-pihole" ''
    #!/usr/bin/env bash

    # Script to unlock the /sda partition and setup its files.

    # check if the current user is root
    if [ "$(id -u)" != "0" ]; then
      echo "This script must be run as root" 1>&2
      exit 1
    fi

    # local storage partition
    echo "Unlocking storage partition:"
    cryptsetup luksOpen /dev/disk/by-uuid/b09893d7-cc1f-4482-bf7a-126d03923b45 sda

    # mount local storage
    if [ ! -f /dev/mapper/sda ]; then
      echo "Mounting and symlinking home:"
      mount -o relatime /dev/mapper/sda /sda

      if [ $? -eq "0" ]; then
        # Symlink @home files out into my actual home
        # See https://superuser.com/a/633610

        ln -s /sda/@home/* /home/aires
      else
        echo "Failed to mount @home"
      fi

      echo "Mounting and symlinking swap:"
      mount -o subvol=@swap,noatime /dev/mapper/sda /swap

      if [ $? -eq "0" ]; then
        swapon /swap/swapfile
      else
        echo "Failed to mount swap"
      fi
    else
      echo "Failed to unlock sda."
    fi

    exit 0
  '';
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking = {
    hostName = hostName;

    # Connect to the network automagically
    networkmanager.enable = lib.mkForce false;
    wireless = {
      enable = true;
      networks = {
        "${config.${namespace}.secrets.networking.networks.home.SSID}" = {
          psk = "${config.${namespace}.secrets.networking.networks.home.password}";
        };
      };
    };
  };

  # Disable smartd: daemon fails when it doesn't detect any drives to monitor on startup
  services.smartd.enable = lib.mkForce false;

  ${namespace} = {
    bootloader.enable = false; # Bootloader configured in hardware-configuration.nix

    editor = "nano";

    packages = with pkgs; [
      btrfs-progs
      cryptsetup
      libraspberrypi
      linuxKernel.kernels.linux_rpi4
      raspberrypifw
      raspberrypi-eeprom
      start-pihole_script
    ];
    services = {
      autoUpgrade = {
        enable = true;
        configDir = config.${namespace}.secrets.nixConfigFolder;
        onCalendar = "daily";
        user = config.users.users.aires.name;
      };
      ssh = {
        enable = true;
        ports = [ config.${namespace}.secrets.hosts.hevana.ssh.port ];
      };
      tor = {
        enable = true;
        snowflake-proxy.enable = true;
      };
    };
    users.aires.enable = true;
  };
}
