{
  config,
  lib,
  pkgs,
  ...
}:

# Gaming-related settings
let
  cfg = config.aux.system.apps.gaming;
  reset-controllers-script = pkgs.writeShellScriptBin "reset-controllers" ''
    #!/usr/bin/env bash
    sudo rmmod hid_xpadneo && sudo modprobe hid_xpadneo
    sudo systemctl restart bluetooth.service
  '';

  # vendorID and product ID for Victrix Pro BFG controller
  vendorID = "0e6f";
  productID = "024b";

  # Bluetooth config for Victrix PDP pro
  vitrix-pdp-pro-bluetooth = pkgs.writeText "info" (builtins.readFile ./bluetooth/vitrix-pdp-pro);
in
{
  options = {
    aux.system.apps.gaming.enable = lib.mkEnableOption "Enables gaming features";
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.flatpak = {
      enable = true;
      packages = [
        "gg.minion.Minion"
        "com.valvesoftware.Steam"
        "org.firestormviewer.FirestormViewer"
      ];
    };

    # Enable Xbox controller driver (XPadNeo)
    hardware.xpadneo.enable = true;

    systemd.tmpfiles.rules = lib.mkIf config.aux.system.bluetooth.enable [
      "d /var/lib/bluetooth/${config.aux.system.bluetooth.adapter}/ 0700 root root" # First, make sure the directory exists
      "L+ /var/lib/bluetooth/${config.aux.system.bluetooth.adapter}/00:34:30:47:37:AB/info - - - - ${vitrix-pdp-pro-bluetooth}"
    ];

    # Create udev rule to force PDP Victrix controller to use xpadneo
    # Udev rule taken from https://github.com/atar-axis/xpadneo/blob/master/hid-xpadneo/etc-udev-rules.d/60-xpadneo.rules
    # Also see https://www.reddit.com/r/linuxquestions/comments/rcx182/why_cant_i_write_to_sysbushiddriversxpadneonew_id/
    services.udev.extraRules = ''
      ACTION=="add", ATTRS{id/vendor}==${vendorID}, ATTRS{id/product}==${productID}, RUN+="${pkgs.bash}/bin/bash -c 'echo 0x03 ${vendorID} ${productID} > /sys/bus/hid/drivers/xpadneo/new_id && echo 0x05 ${vendorID} ${productID} > /sys/bus/hid/drivers/xpadneo/new_id'"
    '';
    /*
      services.udev.packages = [
        (pkgs.writeTextFile {
          name = "victrix-pro-bfg.rules";
          executable = true;
          destination = "/etc/udev/rules.d/70-victrix-pro-bfg.rules";
          text = ''
            	ACTION=="add", ATTRS{id/vendor}==${vendorID}, ATTRS{id/product}==${productID}, RUN+="${pkgs.bash}/bin/bash -c 'echo 0x03 ${vendorID} ${productID} > /sys/bus/hid/drivers/xpadneo/new_id && echo 0x05 ${vendorID} ${productID} > /sys/bus/hid/drivers/xpadneo/new_id'"
          '';
        })
      ];
    */

    # Add script to restart xpadneo in case of issues
    aux.system.packages = [ reset-controllers-script ];

    # Enable GameMode
    programs.gamemode.enable = true;
  };
}
