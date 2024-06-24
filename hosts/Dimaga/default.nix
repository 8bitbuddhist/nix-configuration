{ pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";

  aux.system = {
    role = "workstation";
    apps = {
      development.enable = true;
      media.enable = true;
      office.enable = true;
      writing.enable = true;
    };
    ui = {
      flatpak.enable = true;
      gnome.enable = true;
    };
    users = {
      aires = {
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
  };

  aux.system.services.autoUpgrade = {
    enable = true;
    configDir = config.secrets.nixConfigFolder;
    onCalendar = "daily";
    user = config.users.users.aires.name;
    push = false;
  };

  # Configure the virtual machine created by nixos-rebuild build-vm
  virtualisation.vmVariant.virtualisation = {
    memorySize = 2048;
    cores = 2;
  };
}
