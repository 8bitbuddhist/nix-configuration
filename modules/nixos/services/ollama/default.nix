# FIXME: Clean up
{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services;

  api.port = 11434;
  webui.port = 8130;
  user = "ollama";
  group = "ollama";
in
{
  options = {
    ${namespace}.services = {
      ollama = {
        enable = lib.mkEnableOption "Enables Ollama.";
        home = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "Where to store Ollama's files";
          example = "/var/lib/ollama";
        };
      };
      open-webui = {
        enable = lib.mkEnableOption "Enables Ollama.";
        url = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "The complete URL where Open-WebUI is hosted.";
          example = "https://open-webui.example.com";
        };
        home = lib.mkOption {
          default = "/var/lib/open-webui";
          type = lib.types.str;
          description = "Where to store Open-webUI's files";
          example = "/var/lib/open-webui";
        };
      };
    };
  };

  config = lib.mkIf cfg.ollama.enable {
    services = {
      ollama = {
        enable = true;
        acceleration =
          with config.${namespace}.gpu;
          if amd.enable then
            "rocm"
          else if nvidia.enable then
            "cuda"
          else
            false;
        home = cfg.ollama.home;
        port = api.port;
        user = user;
        group = group;
      };

      open-webui = lib.mkIf cfg.open-webui.enable {
        enable = true;
        port = webui.port;
        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          OLLAMA_BASE_URL = "http://127.0.0.1:${builtins.toString api.port}";
        };
        stateDir = cfg.open-webui.home;
      };

      nginx.virtualHosts."${cfg.open-webui.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.open-webui.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString webui.port}";
          extraConfig = "proxy_ssl_server_name on;";
        };
      };
    };

    systemd.services = {
      ollama.unitConfig.RequiresMountsFor = cfg.ollama.home;
      open-webui = {
        serviceConfig = {
          User = user;
          Group = group;
        };

        unitConfig.RequiresMountsFor = cfg.open-webui.home;
        wants = [ config.systemd.services.ollama.name ];
      };
      nginx.wants = [ config.systemd.services.open-webui.name ];
    };
  };
}
