{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Copy bluetooth device configs
  shure-aonic-bluetooth = pkgs.writeText "info" (
    builtins.readFile ./bluetooth/shure-aonic-bluetooth-params
  );
  xbox-elite-bluetooth = pkgs.writeText "info" (
    builtins.readFile ./bluetooth/xbox-elite-controller-bluetooth-params
  );
  mano-touchpad-bluetooth = pkgs.writeText "info" (
    builtins.readFile ./bluetooth/mano-touchpad-bluetooth-params
  );
  vitrix-pdp-pro-bluetooth = pkgs.writeText "info" (
    builtins.readFile ./bluetooth/vitrix-pdp-pro-params
  );

  # Use gremlin user's monitor configuration for GDM (desktop monitor primary). See https://discourse.nixos.org/t/gdm-monitor-configuration/6356/4
  monitorsXmlContent = builtins.readFile ./monitors.xml;
  monitorsConfig = pkgs.writeText "gdm_monitors.xml" monitorsXmlContent;
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = "24.05";

  aux.system = {
    apps = {
      development.enable = true;
      dj.enable = true;
      gaming.enable = true;
      media.enable = true;
      office.enable = true;
      recording.enable = true;
      social.enable = true;
      writing = {
        enable = true;
        languagetool.enable = true;
      };
    };
    gpu.amd.enable = true;
    packages = with pkgs; [ boinc ];
    retentionPeriod = "7d";
    services.autoUpgrade = {
      enable = true;
      configDir = config.secrets.nixConfigFolder;
      onCalendar = "daily";
      user = config.users.users.aires.name;
    };
    ui = {
      flatpak.enable = true;
      desktops.gnome.enable = true;
    };
    users = {
      aires = {
        enable = true;
        services.syncthing = {
          enable = true;
          enableTray = false; # Recent versions of STT don't recognize Gnome's tray. Uninstalling for now.
        };
      };
      gremlin = {
        enable = true;
        services.syncthing = {
          enable = true;
          enableTray = false;
        };
      };
    };
  };

  # Enable virtual machine manager
  programs.virt-manager.enable = true;

  # Move files into target system
  systemd.tmpfiles.rules = [
    # Use gremlin user's monitor config for GDM (defined above)
    "L+ /run/gdm/.config/monitors.xml - - - - ${monitorsConfig}"

    # Install Bluetooth device profiles
    "d /var/lib/bluetooth/AC:50:DE:9F:AB:88/ 0700 root root" # First, make sure the directory exists
    "L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/00:0E:DD:72:2F:0C/info - - - - ${shure-aonic-bluetooth}"
    "L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/F4:6A:D7:3A:16:75/info - - - - ${xbox-elite-bluetooth}"
    "L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/F8:5D:3C:7D:9A:00/info - - - - ${mano-touchpad-bluetooth}"
    "L+ /var/lib/bluetooth/AC:50:DE:9F:AB:88/00:34:30:47:37:AB/info - - - - ${vitrix-pdp-pro-bluetooth}"
  ];

  # Configure the virtual machine created by nixos-rebuild build-vm
  virtualisation.vmVariant.virtualisation = {
    memorySize = 4096;
    cores = 4;
  };
}
