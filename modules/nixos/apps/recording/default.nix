{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.apps.recording;
in
{
  options = {
    ${namespace}.apps.recording.enable = lib.mkEnableOption "Enables video editing tools";
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.ui.flatpak.enable = true;

    services.flatpak.packages = [
      "com.obsproject.Studio"
      "org.kde.kdenlive"
      "org.tenacityaudio.Tenacity"
      "io.github.seadve.Kooha"
    ];

    environment.systemPackages = with pkgs; [ droidcam ];

    # Add a virtual camera to use with Droidcam
    boot = {
      extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback.out ];
      kernelModules = [ "v4l2loopback" ];
      # Note on v4l2loopback kernel module parameters:
      # 	exclusive_caps: Skype, Zoom, Teams etc. will only show device when actually streaming. This MUST be set to 1 for Chrome to detect virtual cameras.
      # 	card_label: Name of virtual camera, how it'll show up in Skype, Zoom, Teams
      # 	https://github.com/umlaeute/v4l2loopback
      extraModprobeConfig = ''
        options v4l2loopback exclusive_caps=1 card_label="Droidcam" set_fps=30
      '';
    };
  };
}
