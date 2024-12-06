{ config, lib, ... }:
let
  cfg = config.aux.system.services.apcupsd;
in
{
  options = {
    aux.system.services.apcupsd = {
      enable = lib.mkEnableOption "Enables apcupsd";
      configText = lib.mkOption {
        type = lib.types.str;
        description = "The configuration to pass to apcupsd.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.apcupsd = {
      enable = true;
      configText = cfg.configText;
    };
  };
}
