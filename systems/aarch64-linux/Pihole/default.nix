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

  ${namespace} = {
    bootloader.enable = false; # Bootloader configured in hardware-configuration.nix

    editor = "nano";

    packages = with pkgs; [
      btrfs-progs
      cryptsetup
      libraspberrypi
      raspberrypifw
      raspberrypi-eeprom
      linuxKernel.kernels.linux_rpi4
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
