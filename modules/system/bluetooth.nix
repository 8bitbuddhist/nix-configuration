# Configures bluetooth.
{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.bluetooth;

  # Copy bluetooth device configs
  shure-aonic-bluetooth = pkgs.writeText "info" (builtins.readFile ./bluetooth/shure-aonic-tw2);
in
{

  options = {
    aux.system.bluetooth = {
      enable = lib.mkEnableOption "Enables bluetooth.";
      adapter = lib.mkOption {
        type = lib.types.str;
        description = "The MAC address of your primary Bluetooth adapter Used to install device configs.";
        default = "";
      };
      experimental.enable = lib.mkEnableOption "Enables experimental features, like device power reporting.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Set up Bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = lib.mkIf cfg.experimental.enable {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
          KernelExperimental = true;
        };
      };
    };

    # Add Bluetooth LE audio support
    environment.systemPackages = with pkgs; [ liblc3 ];

    # Install Bluetooth device profiles
    systemd.tmpfiles.rules = lib.mkIf (cfg.adapter != "") [
      "d /var/lib/bluetooth/${cfg.adapter}/ 0700 root root" # First, make sure the directory exists
      "L+ /var/lib/bluetooth/${cfg.adapter}/00:0E:DD:72:2F:0C/info - - - - ${shure-aonic-bluetooth}"
    ];
  };
}
