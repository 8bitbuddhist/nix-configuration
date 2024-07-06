{
  config,
  pkgs,
  lib,
  nix-secrets,
  ...
}:
let
  stateVersion = "24.05";
  hostName = "Pihole";
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  aux.system = {
    apps.tmux.enable = true;
    bootloader.enable = false; # Bootloader configured in hardware-configuration.nix
    packages = with pkgs; [
      libraspberrypi
      raspberrypifw
      raspberrypi-eeprom
      linuxKernel.kernels.linux_rpi4
    ];
    services.ssh = {
      enable = true;
      ports = [ config.secrets.hosts.haven.ssh.port ];
    };
    users.aires.enable = true;
  };

  nix.distributedBuilds = true;

  time.timeZone = "America/New_York";

  # Connect to the network automagically
  networking = {
    networkmanager.enable = lib.mkForce false;
    wireless.networks = {
      "${config.secrets.networking.networks.home.SSID}" = {
        psk = "${config.secrets.networking.networks.home.password}";
      };
    };
  };
}
