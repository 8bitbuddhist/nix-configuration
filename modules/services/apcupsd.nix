{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.services.apcupsd;
in
with lib;
{
  options = {
    aux.system.services.apcupsd = {
      enable = mkEnableOption (mdDoc "Enables apcupsd");
      configText = lib.mkOption {
        type = lib.types.str;
        description = "The configuration to pass to apcupsd.";
      };
    };
  };

  config = mkIf cfg.enable {
    services.apcupsd = {
      enable = true;
      configText = cfg.configText;
    };
  };
}
