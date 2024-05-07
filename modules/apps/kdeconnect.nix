{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.host.apps.kdeconnect;
in
with lib;
{
  options = {
    host.apps.kdeconnect.enable = mkEnableOption (mdDoc "Enables KDE Connect");
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ gnomeExtensions.gsconnect ];

    networking.firewall = {
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
