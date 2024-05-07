{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.host.services.apcupsd;
in
with lib;
{
  options = {
    host.services.apcupsd.enable = mkEnableOption (mdDoc "Enables apcupsd");
  };

  config = mkIf cfg.enable {
    services.apcupsd = {
      enable = true;
      configText = builtins.readFile ./etc/apcupsd.conf;
    };
  };
}
