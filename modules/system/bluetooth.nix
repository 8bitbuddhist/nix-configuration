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
      enable = lib.mkEnableOption (lib.mdDoc "Enables bluetooth");
    };
  };

  config = lib.mkIf cfg.enable {
    # Set up Bluetooth
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
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
