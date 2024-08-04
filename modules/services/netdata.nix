{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.services.netdata;
in
{
  options = {
    aux.system.services.netdata = {
      enable = lib.mkEnableOption "Enables Netdata monitoring.";
      auth = {
        user = lib.mkOption {
          default = "netdata";
          type = lib.types.str;
          description = "Username for basic auth.";
        };
        password = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "Password for basic auth.";
        };
      };
      domain = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The root domain that Netdata will be hosted on.";
        example = "example.com";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Netdata is hosted.";
        example = "https://netdata.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = cfg.domain;
        forceSSL = true;
        basicAuth = {
          "${cfg.auth.user}" = cfg.auth.password;
        };
        locations."/" = {
          proxyPass = "http://127.0.0.1:19999";
          proxyWebsockets = true;
          extraConfig = ''
            # Taken from https://learn.netdata.cloud/docs/netdata-agent/configuration/running-the-netdata-agent-behind-a-reverse-proxy/nginx
            proxy_set_header X-Forwarded-Host $host;
            proxy_set_header X-Forwarded-Server $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_pass_request_headers on;
            proxy_set_header Connection "keep-alive";
            proxy_store off;
          '';
        };
      };

      netdata = {
        enable = true;
        enableAnalyticsReporting = false;
        configDir = {
          # Enable nvidia-smi: https://nixos.wiki/wiki/Netdata#nvidia-smi
          "python.d.conf" = pkgs.writeText "python.d.conf" ''
            nvidia_smi: yes
          '';
        };
      };
    };
    systemd.services.nginx.wants = [ config.systemd.services.netdata.name ];
  };
}
