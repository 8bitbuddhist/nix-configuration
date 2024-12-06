{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.apps.office;
in
{
  options = {
    ${namespace}.apps.office.enable = lib.mkEnableOption "Enables office and workstation apps";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.ui.flatpak = {
      enable = true;
      packages = [
        "org.onlyoffice.desktopeditors"
        "us.zoom.Zoom"
      ];
    };
  };
}
