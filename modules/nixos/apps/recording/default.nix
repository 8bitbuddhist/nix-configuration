{
  config,
  lib,
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
  };
}
