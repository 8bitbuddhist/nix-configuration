{ config, lib, ... }:

let
  cfg = config.aux.system.apps.dj;
in
{
  options = {
    aux.system.apps.dj.enable = lib.mkEnableOption "Enables DJing tools (i.e. Mixxx)";
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.flatpak = {
      enable = true;
      packages = [ "org.mixxx.Mixxx" ];
    };
  };
}
