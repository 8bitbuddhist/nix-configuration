# Configures bluetooth.
{
  lib,
  config,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.bluetooth;
in
{

  options = {
    ${namespace}.bluetooth = {
      enable = lib.mkEnableOption "Enables bluetooth.";
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

          # Additional options based on:
          # https://www.reddit.com/r/NixOS/comments/1hdsfz0/what_do_i_have_to_do_to_make_my_xbox_controller/
          JustWorksRepairing = "always";
          FastConnectable = true;
        };
      };
    };

    # Add Bluetooth LE audio support
    environment.systemPackages = with pkgs; [ liblc3 ];
  };
}
