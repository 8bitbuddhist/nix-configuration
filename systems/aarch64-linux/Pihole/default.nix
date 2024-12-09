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
    wireless.networks = {
      "${config.${namespace}.secrets.networking.networks.home.SSID}" = {
        psk = "${config.${namespace}.secrets.networking.networks.home.password}";
      };
    };
  };

  ${namespace} = {
    bootloader.enable = false; # Bootloader configured in hardware-configuration.nix
    packages = with pkgs; [
      libraspberrypi
      raspberrypifw
      raspberrypi-eeprom
      linuxKernel.kernels.linux_rpi4
    ];
    services.ssh = {
      enable = true;
      ports = [ config.${namespace}.secrets.hosts.hevana.ssh.port ];
    };
    users.aires.enable = true;
  };
}
