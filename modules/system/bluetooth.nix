# Configures bluetooth.
{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.bluetooth;
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
  };
}
