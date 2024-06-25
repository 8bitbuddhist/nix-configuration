{ config, lib, ... }:

let
  cfg = config.aux.system.apps.office;
in
with lib;
{
  options = {
    aux.system.apps.office.enable = mkEnableOption (mdDoc "Enables office and workstation apps");
  };

  config = mkIf cfg.enable {
    aux.system.ui.flatpak = {
      enable = true;
      packages = [
        "org.onlyoffice.desktopeditors"
        "us.zoom.Zoom"
      ];
    };
  };
}
