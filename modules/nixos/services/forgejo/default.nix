{
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.services.forgejo;
in
{
  options = {
    aux.system.services.forgejo = {
      enable = lib.mkEnableOption "Enables Forgejo Git hosting service.";
      home = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Where to store Forgejo's files";
        example = "/home/forgejo";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Forgejo is hosted.";
        example = "https://forgejo.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      forgejo = {
        enable = true;
        settings = {
          server = {
            DOMAIN = lib.Sapana.getDomainFromURI cfg.url;
            ROOT_URL = cfg.url;
            HTTP_PORT = 3000;
          };
          indexer.REPO_INDEXER_ENABLED = true; # Enable code indexing
        };
        useWizard = true;
      } // lib.optionalAttrs (cfg.home != null) { stateDir = cfg.home; };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.Sapana.getDomainFromURI cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
          extraConfig = "proxy_ssl_server_name on;"; # required when the target is also TLS server with multiple hosts
        };
      };
    };

    systemd.services = {
      forgejo.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.forgejo.name ];
    };
  };
}
