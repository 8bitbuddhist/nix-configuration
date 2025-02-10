# Sets up an observability stack with Prometheus, Grafana, and Loki
# Follows https://xeiaso.net/blog/prometheus-grafana-loki-nixos-2020-11-20/

# FIXME: Finish setting up observability stack
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.observability;
in
{
  options = {
    ${namespace}.services.observability = {
      enable = lib.mkEnableOption "Enables monitoring via Prometheus, Grafana, and Loki.";
      grafana = {
        home = lib.mkOption {
          default = "/var/lib/grafana";
          type = lib.types.str;
          description = "Where to store Grafana's files.";
        };
        port = lib.mkOption {
          default = 2342;
          type = lib.types.int;
          description = "The port to host Grafana on.";
        };
      };
      loki.port = lib.mkOption {
        default = 3030;
        type = lib.types.int;
        description = "The port to host Loki on.";
      };
      promtail.port = lib.mkOption {
        default = 3031;
        type = lib.types.int;
        description = "The port to host Grafana on.";
      };
      prometheus.port = lib.mkOption {
        default = 3020;
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
        settings = {
          analytics.reporting_enabled = false;
          server = {
            domain = lib.${namespace}.getDomainFromURI cfg.url;
            http_addr = "127.0.0.1";
            http_port = cfg.grafana.port;
          };
        };
        dataDir = cfg.grafana.home;
        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              access = "proxy";
              url = "http://127.0.0.1:${toString cfg.prometheus.port}";
            }
            {
              name = "Loki";
              type = "loki";
              access = "proxy";
              url = "http://127.0.0.1:${toString cfg.loki.port}";
            }
          ];
        };
      };

      loki = {
        enable = true;
        configuration = {
          server.http_listen_port = cfg.loki.port;
          auth_enabled = false;

          ingester = {
            lifecycler = {
              address = "127.0.0.1";
              ring = {
                kvstore = {
                  store = "inmemory";
                };
                replication_factor = 1;
              };
            };
            chunk_idle_period = "1h";
            max_chunk_age = "1h";
            chunk_target_size = 999999;
            chunk_retain_period = "30s";
          };

          schema_config = {
            configs = [
              {
                from = "2025-02-01";
                store = "boltdb";
                object_store = "filesystem";
                schema = "v13";
                index = {
                  prefix = "index_";
                  period = "24h";
                };
              }
            ];
          };

          storage_config = {
            boltdb = {
              directory = "/var/lib/loki/index";
            };
            filesystem = {
              directory = "/var/lib/loki/chunks";
            };
          };

          limits_config = {
            allow_structured_metadata = false;
            reject_old_samples = true;
            reject_old_samples_max_age = "168h";
          };

          table_manager = {
            retention_deletes_enabled = false;
            retention_period = "0s";
          };

          compactor = {
            working_directory = "/var/lib/loki";
            compactor_ring = {
              kvstore = {
                store = "inmemory";
              };
            };
          };
        };
      };

      # Promtail sends logs into Loki
      promtail = {
        enable = true;
        configuration = {
          server = {
            http_listen_port = cfg.promtail.port;
            grpc_listen_port = 0;
          };
          positions = {
            filename = "/tmp/positions.yaml";
          };
          clients = [
            {
              url = "http://127.0.0.1:${toString cfg.loki.port}/loki/api/v1/push";
            }
          ];
          scrape_configs = [
            {
              job_name = "journal";
              journal = {
                max_age = "12h";
                labels = {
                  job = "systemd-journal";
                  host = config.networking.hostName;
                };
              };
              relabel_configs = [
                {
                  source_labels = [ "__journal__systemd_unit" ];
                  target_label = "unit";
                }
              ];
            }
          ];
        };
      };

      prometheus = {
        enable = true;
        port = cfg.prometheus.port;
        exporters = {
          # Export this node's statistics
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
          };
        };
        # Ingest statistics from nodes
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

      # Taken from https://grafana.com/tutorials/run-grafana-behind-a-proxy/
      nginx = {
        /*
          FIXME: Nginx fails to start if this upstream is defined
          upstreams."grafana" = {
            servers = {
              "http://127.0.0.1:${builtins.toString cfg.grafana.port}" = {
                weight = 1;
              };
            };
          };
        */
        virtualHosts."${cfg.url}" = {
          useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://127.0.0.1:${builtins.toString cfg.grafana.port}";
            proxyWebsockets = true;
            extraConfig = ''
              # Taken from https://learn.netdata.cloud/docs/netdata-agent/configuration/running-the-netdata-agent-behind-a-reverse-proxy/nginx
              proxy_set_header Host $host;
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Server $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_pass_request_headers on;
              proxy_set_header Connection "keep-alive";
              proxy_store off;
            '';
          };
        };
      };
    };

    systemd.services = {
      nginx.wants = [ config.systemd.services.grafana.name ];
    };
  };
}
