{ config, lib, ... }:

let 
  cfg = config.host.apps.media;
in
with lib;
{
  options = {
    host.apps.media.enable = mkEnableOption (mdDoc "Enables media playback and editing apps");
  };

  config = mkIf cfg.enable {
    host.ui.flatpak.enable = true;

    services.flatpak = {
      packages = [
        "com.calibre_ebook.calibre"
        "com.github.unrud.VideoDownloader"
        "io.github.celluloid_player.Celluloid"
        "org.kde.krita"
        "org.kde.KStyle.Adwaita//5.15-23.08"  # Retrieved from https://docs.flatpak.org/en/latest/desktop-integration.html
        "org.kde.KStyle.Adwaita//6.5"
        "org.kde.WaylandDecoration.QAdwaitaDecorations//5.15-23.08"	# Replaced deprecated QGnomePlatform https://wiki.archlinux.org/title/Uniform_look_for_Qt_and_GTK_applications
        "org.kde.WaylandDecoration.QAdwaitaDecorations//6.5"
      ];
    };
  };
}