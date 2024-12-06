{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.apps.social;
in
{
  options = {
    aux.system.apps.social.enable = lib.mkEnableOption "Enables chat apps";
  };

  config = lib.mkIf cfg.enable {
    aux.system = {
      packages = [ pkgs.beeper ];
      ui.flatpak = {
        enable = true;
        packages = [
          "com.discordapp.Discord"
          "dev.geopjr.Tuba"
        ];
      };
    };
  };
}
