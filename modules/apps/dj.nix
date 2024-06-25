{ config, lib, ... }:

let
  cfg = config.aux.system.apps.dj;
in
with lib;
{
  options = {
    aux.system.apps.dj.enable = mkEnableOption (mdDoc "Enables DJing tools (i.e. Mixxx)");
  };

  config = mkIf cfg.enable {
    aux.system.ui.flatpak = {
      enable = true;
      packages = [ "org.mixxx.Mixxx" ];
    };
  };
}
