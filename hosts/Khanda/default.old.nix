{ pkgs, lib, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";
  system.autoUpgrade.enable = lib.mkForce false;

  aux.system = {
    role = "workstation";
    apps = {
      development.enable = true;
      media.enable = true;
      office.enable = true;
      recording.enable = true;
      social.enable = true;
      writing = {
        enable = true;
        languagetool.enable = false;
      };
    };
    ui = {
      flatpak.enable = true;
      gnome.enable = true;
    };
    users.aires = {
      enable = true;
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

  # Limit the number of cores Nix can use
  nix.settings.cores = 10;

  # Configure the virtual machine created by nixos-rebuild build-vm
  virtualisation.vmVariant.virtualisation = {
    memorySize = 2048;
    cores = 2;
  };
}
