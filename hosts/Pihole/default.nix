{
  config,
  pkgs,
  lib,
  nix-secrets,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";

  aux.system = {
    apps.tmux.enable = true;
    bootloader.enable = false;  # Bootloader configured in hardware-configuration.nix
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
    hostName = "Pihole";
    networkmanager.enable = lib.mkForce false;
    wireless.networks = {
      "${config.secrets.networking.networks.home.SSID}" = {
        psk = "${config.secrets.networking.networks.home.password}";
      };
    };
  };
}
