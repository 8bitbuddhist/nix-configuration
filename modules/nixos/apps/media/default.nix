{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.apps.media;
in
{
  options = {
    ${namespace}.apps.media = {
      enable = lib.mkEnableOption "Enables media playback and editing apps.";
      mixxx.enable = lib.mkEnableOption "Installs the Mixxx DJing software.";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.ui.flatpak = {
      enable = true;
      packages = [
        "app.drey.EarTag"
        "com.calibre_ebook.calibre"
        "com.github.unrud.VideoDownloader"
        "io.freetubeapp.FreeTube"
        "org.kde.digikam"
        "org.kde.krita"
        "org.kde.KStyle.Adwaita//5.15-23.08" # Retrieved from https://docs.flatpak.org/en/latest/desktop-integration.html
        "org.kde.KStyle.Adwaita//6.6"
        "org.kde.WaylandDecoration.QAdwaitaDecorations//5.15-23.08" # Replaced deprecated QGnomePlatform https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications
        "org.kde.WaylandDecoration.QAdwaitaDecorations//6.6"
        (lib.mkIf cfg.mixxx.enable "org.mixxx.Mixxx")
        "org.videolan.VLC"
      ];
    };
  };
}
