# See https://wiki.nixos.org/wiki/Syncthing
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.syncthing;
in
{
  options = {
    ${namespace}.services.syncthing = {
      enable = lib.mkEnableOption "Enables Syncthing.";
      home = lib.mkOption {
        default = "/var/lib/syncthing";
        type = lib.types.str;
        description = "Where to store Syncthing's configuration files";
      };
      tray.enable = lib.mkEnableOption "Enables the Syncthing Tray applet.";
      user = lib.mkOption {
        type = lib.types.str;
        default = "syncthing";
        description = "User account under which Syncthing runs.";
      };
      web = {
        enable = lib.mkEnableOption "Enables the Syncthing web UI.";
        port = lib.mkOption {
          type = lib.types.int;
          default = 8384;
          description = "The port to host Syncthing web on.";
        };
        public = lib.mkEnableOption "Whether to expose the Syncthing web UI to the network.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # If the web UI is public, open the port in the firewall
    networking.firewall.allowedTCPPorts = with cfg.web; lib.mkIf (enable && public) [ port ];

    services = {
      flatpak.packages = lib.mkIf (config.${namespace}.ui.flatpak.enable && cfg.tray.enable) [
        "io.github.martchus.syncthingtray"
      ];

      syncthing = {
        enable = true;
        user = cfg.user;
        group = config.users.users.${cfg.user}.group;
        configDir = cfg.home;
        guiAddress =
          let
            listenAddress = with cfg.web; (if (enable && public) then "0.0.0.0" else "127.0.0.1");
          in
          "${listenAddress}:${builtins.toString cfg.web.port}";
      };
    };

    systemd.services.syncthing = {
      environment.STNODEFAULTFOLDER = "true"; # Don't create default ~/Sync folder
      unitConfig.RequiresMountsFor = cfg.home;
    };
  };
}
