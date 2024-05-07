{ config, lib, ... }:

let
  cfg = config.host.apps.dj;
in
with lib;
{
  options = {
    host.apps.dj.enable = mkEnableOption (mdDoc "Enables DJing tools (i.e. Mixxx)");
  };

  config = mkIf cfg.enable {
    host.ui.flatpak.enable = true;

    services.flatpak.packages = [ "org.mixxx.Mixxx" ];
  };
}
