{ config, lib, ... }:

let
  cfg = config.aux.system.services.deluge;
in
{
  options = {
    aux.system.services.deluge = {
      enable = lib.mkEnableOption "Enables Deluge.";
      home = lib.mkOption {
        default = "/var/lib/deluge";
        type = lib.types.str;
        description = "Where to store Deluge's files";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Deluge is hosted.";
        example = "https://deluge.example.com";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost =
          let
            parsedURL = (lib.strings.splitString "." cfg.url);
          in
          builtins.concatStringsSep "." [
            (builtins.elemAt parsedURL 1)
            (builtins.elemAt parsedURL 2)
          ];
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8112";
          extraConfig = ''
            proxy_set_header X-Deluge-Base "/";
            add_header X-Frame-Options SAMEORIGIN;
          '';
        };
      };
      deluge = {
        enable = true;
        dataDir = cfg.home;
        web = {
          enable = true;
          openFirewall = false; # Not needed since we're using a reverse proxy
        };
      };
    };

    systemd.services = {
      deluge.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.deluge.name ];
    };
  };
}
