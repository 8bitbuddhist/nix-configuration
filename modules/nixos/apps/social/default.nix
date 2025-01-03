{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.apps.social;
in
{
  options = {
    ${namespace}.apps.social.enable = lib.mkEnableOption "Enables chat apps";
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      packages = [ pkgs.beeper ];
      ui.flatpak = {
        enable = true;
        packages = [
          "com.discordapp.Discord"
          "org.gnome.Polari" # IRC client
        ];
      };
    };
  };
}
