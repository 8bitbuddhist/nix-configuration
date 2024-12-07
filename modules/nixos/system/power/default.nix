# Power management options
{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace};

  ppd-patched = pkgs.power-profiles-daemon.overrideAttrs (
    _finalAttrs: _prevAttrs: {
      patches = [ ./power-profiles-daemon.patch ];
      mesonFlags = [
        "-Dsystemdsystemunitdir=${placeholder "out"}/lib/systemd/system"
        "-Dgtk_doc=true"
        "-Dpylint=disabled"
        "-Dzshcomp=${placeholder "out"}/share/zsh/site-functions"
        "-Dtests=false" # Disable built-in tests, since they'll fail due to the patch
      ];
    }
  );
in
{
  options.${namespace}.powerManagement.enable =
    lib.mkEnableOption "Enables power management, e.g. for laptops.";

  # Configure power management via power-profiles-daemon
  # https://gitlab.freedesktop.org/upower/power-profiles-daemon
  config.services.power-profiles-daemon = lib.mkIf cfg.powerManagement.enable {
    enable = true;
    package = ppd-patched;
  };
}
