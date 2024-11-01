{
  pkgs,
  config,
  lib,
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
      allowUnfree = true;
      ui.flatpak = {
        enable = true;
        packages = [ "com.discordapp.Discord" ];
      };
    };
  };
}
