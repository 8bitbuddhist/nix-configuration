{ pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";
  system.autoUpgrade.enable = lib.mkForce false;

  host = {
    role = "workstation";
    apps = {
      development.enable = true;
      kdeconnect.enable = true;
      media.enable = true;
      office.enable = true;
      social.enable = true;
      writing.enable = true;
    };
    ui = {
      flatpak.enable = true;
      gnome.enable = true;
    };
    users.aires = {
      enable = true;
      autologin = true;
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

  # Enable thermal control
  services.thermald.enable = true;

  # Limit the number of cores Nix can use so at least one is always free
  nix.settings.cores = 11;

  # Configure the virtual machine created by nixos-rebuild build-vm
  virtualisation.vmVariant.virtualisation = {
    memorySize = 2048;
    cores = 2;
  };
}
