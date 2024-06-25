{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.aux.system.apps.social;
in
with lib;
{
  options = {
    aux.system.apps.social.enable = mkEnableOption (mdDoc "Enables chat apps");
  };

  config = mkIf cfg.enable {
    aux.system = {
      allowUnfree = true;
      ui.flatpak = {
        enable = true;
        packages = [ "com.discordapp.Discord" ];
      };
    };

    # Check Beeper Flatpak status here: https://github.com/daegalus/beeper-flatpak-wip/issues/1
    environment.systemPackages = [ pkgs.beeper ];
  };
}
