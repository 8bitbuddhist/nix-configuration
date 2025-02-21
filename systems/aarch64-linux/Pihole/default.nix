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

  # Disable smartd: daemon fails when it doesn't detect any drives to monitor on startup
  services.smartd.enable = lib.mkForce false;

  # Install Docker for Kubernetes in Docker (Kind)
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  ${namespace} = {
    bootloader.enable = false; # Bootloader configured in hardware-configuration.nix

    packages = with pkgs; [
      btrfs-progs
      cryptsetup
      libraspberrypi
      linuxKernel.kernels.linux_rpi4
      raspberrypifw
      raspberrypi-eeprom

      # Gremlin lab tools
      pkgs.unstable.kind
      pkgs.unstable.kubectl
      pkgs.unstable.kubernetes-helm
    ];
    services = {
      autoUpgrade.enable = false;
      ssh = {
        enable = true;
        ports = [ config.${namespace}.secrets.hosts.hevana.ssh.port ];
      };
    };
    users.aires.enable = true;
  };
}
