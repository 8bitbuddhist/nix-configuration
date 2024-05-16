{
  pkgs,
  lib,
  nix-secrets,
  ...
}:
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";

  host = {
    role = "server";
    users.aires.enable = true;
    boot.enable = false;
  };

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
      "${nix-secrets.networking.networks.home.SSID}" = {
        psk = "${nix-secrets.networking.networks.home.password}";
      };
    };
  };

  # Enable SSH
  services.openssh = {
    enable = true;
    ports = [ 33105 ];

    settings = {
      PasswordAuthentication = true;
      AllowUsers = [ "aires" ];
      PermitRootLogin = "no";
    };
  };
}
