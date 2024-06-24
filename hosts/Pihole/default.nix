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
    users.aires.enable = true;
    boot.enable = false;
    services.ssh = {
      enable = true;
      ports = [ config.secrets.hosts.haven.ssh.port ];
    };
  };

  nix.distributedBuilds = true;

  networking.hostName = "Pihole";
  time.timeZone = "America/New_York";

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypifw
    raspberrypi-eeprom
    linuxKernel.kernels.linux_rpi4
  ];

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
