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
        #"us.zoom.Zoom"
      ];
    };

    # Downgrade Zoom due to https://github.com/flathub/us.zoom.Zoom/issues/471
    services.flatpak.packages = [
      {
        appId = "us.zoom.Zoom";
        commit = "b9505f108b5f9acb2bbad83ac66f97b42bc6a75b9c28ed7b75dec1040e013305";
      }
    ];
  };
}
