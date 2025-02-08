# Sets up an observability stack with Prometheus, Grafana, and Loki
# Follows https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20/

# FIXME: Set up o11y
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:

let
  cfg = config.${namespace}.services.observability;
in
{
  options = {
    ${namespace}.services.observability = {
      enable = lib.mkEnableOption "Enables monitoring via Prometheus, Grafana, and Loki.";
      home = lib.mkOption {
        default = "/var/lib/observability";
        type = lib.types.str;
        description = "Where to store files for all three services.";
      };
      port = lib.mkOption {
        default = 2342;
        type = lib.types.int;
        description = "The port to host Grafana on.";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Grafana is hosted.";
        example = "https://ops.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      grafana = {
        enable = true;
        domain = lib.${namespace}.getDomainFromURI cfg.url;
        port = cfg.port;
        addr = "127.0.0.1";
      };
      loki = {
        enable = true;
        configFile = ./loki.yaml;
      };
      prometheus = {
        enable = true;
        port = 9001;
        exporters = {
          # Export this node's statistics
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
            port = 9002;
          };
        };
        # Read statistics exported by this and other hosts
        scrapeConfigs = [
          {
            job_name = "prometheus-ingest";
            static_configs = [
              {
                targets = [ "127.0.0.1:${toString config.services.prometheus.exporters.node.port}" ];
              }
            ];
          }
        ];
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
          proxyWebsockets = true;
        };
      };
    };

    systemd.services = {
      nginx.wants = [ config.systemd.services.monit.name ];
      # Promtail sends logs into Loki
      promtail = {
        description = "Promtail service for Loki";
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          ExecStart = ''
            ${pkgs.grafana-loki}/bin/promtail --config.file ${./promtail.yaml}
          '';
        };
      };
    };
  };
}
