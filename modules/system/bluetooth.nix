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

    # FIXME: Create systemd service to manually start the adapter on boot.
    # This is a workaround for hardware.bluetooth.powerOnBoot not working as expected.
    systemd.services.startBluetooth = {
      description = "Manually starts the Bluetooth service on boot";
      after = [ "bluetooth.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        type = "simple";
        ExecStart = "${pkgs.bluez}/bin/bluetoothctl -- power on";
        Restart = "always";
        RestartSec = "5s";
      };
    };
  };
}
