{ config, lib, ... }:

let
  cfg = config.aux.system.apps.media;
in
{
  options = {
    aux.system.apps.media.enable = lib.mkEnableOption "Enables media playback and editing apps";
  };

  config = lib.mkIf cfg.enable {
    aux.system.ui.flatpak = {
      enable = true;
      packages = [
        "app.drey.EarTag"
        "com.calibre_ebook.calibre"
        "com.github.unrud.VideoDownloader"
        "de.haeckerfelix.Shortwave"
        "io.freetubeapp.FreeTube"
        "io.github.dweymouth.supersonic"
        "org.kde.krita"
        "org.kde.KStyle.Adwaita//5.15-23.08" # Retrieved from https://docs.flatpak.org/en/latest/desktop-integration.html
        "org.kde.KStyle.Adwaita//6.6"
        "org.kde.WaylandDecoration.QAdwaitaDecorations//5.15-23.08" # Replaced deprecated QGnomePlatform https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications
        "org.kde.WaylandDecoration.QAdwaitaDecorations//6.6"
        "org.videolan.VLC"
      ];
    };
  };
}
