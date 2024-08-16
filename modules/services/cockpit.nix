{ config, lib, ... }:
let
  cfg = config.aux.system.services.cockpit;
in
{
  options = {
    aux.system.services.cockpit = {
      enable = lib.mkEnableOption "Enables Cockpit monitoring.";
      domain = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The root domain that Cockpit will be hosted on.";
        example = "example.com";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Cockpit is hosted.";
        example = "https://cockpit.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = cfg.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:9090";
          extraConfig = ''
            # Taken from https://garrett.github.io/cockpit-project.github.io/external/wiki/Proxying-Cockpit-over-NGINX
            # Required to proxy the connection to Cockpit
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-Proto $scheme;

            # Required for web sockets to function
            proxy_http_version 1.1;
            proxy_buffering off;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };

      cockpit = {
        enable = true;
        port = 9090;
        settings = {
          WebService = {
            Origins = "https://${cfg.url} wss://${cfg.url}";
            ProtocolHeader = "X-Forwarded-Proto";
          };
        };
      };
    };
    systemd.services.nginx.wants = [ config.systemd.services.cockpit.name ];

  };
}
