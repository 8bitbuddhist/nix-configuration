{ config, lib, ... }:

let
  cfg = config.aux.system.apps.office;
in
{
  options = {
    aux.system.apps.office.enable = lib.mkEnableOption "Enables office and workstation apps";
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.flatpak = {
      enable = true;
      packages = [
        "org.onlyoffice.desktopeditors"
        "us.zoom.Zoom"
      ];
    };
  };
}
