# Power management options
{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.powerManagement;

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

  config = {
    # Configure power management via power-profiles-daemon
    # https://gitlab.freedesktop.org/upower/power-profiles-daemon
    services.power-profiles-daemon = lib.mkIf cfg.enable {
      enable = true;
      package = ppd-patched;
    };

    # Configure power management via tuned
    # https://github.com/redhat-performance/tuned/
    environment.systemPackages = [ pkgs.${namespace}.tuned ];
    systemd.services.tuned = {
      wantedBy = [ "multi-user.target" ];
      after = [ "dbus.service" ];
      description = "tuned power management daemon.";
      enable = true;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.${namespace}.tuned}/bin/tuned";
      };
    };
    systemd.services.tuned-ppd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "tuned.service" ];
      description = "tuned power management daemon - power-profiles-daemon compatibility.";
      enable = true;
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.${namespace}.tuned}/bin/tuned-ppd";
      };
    };
  };
}
