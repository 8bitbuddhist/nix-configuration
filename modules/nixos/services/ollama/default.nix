{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.open-webui;

  api.port = 11434;
  webui.port = 8130;

  ollamaUser = "ollama";
  ollamaGroup = ollamaUser;
in
{
  options = {
    ${namespace}.services.open-webui = {
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
      };
      ollama = {
        enable = lib.mkEnableOption "Enables Ollama.";
        home = lib.mkOption {
          default = "/var/lib/ollama";
          type = lib.types.str;
          description = "Where to store Ollama's files";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
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
        user = ollamaUser;
      };

      open-webui = {
        enable = true;
        port = webui.port;
        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          OLLAMA_BASE_URL = "http://127.0.0.1:${builtins.toString api.port}";
        };
        stateDir = cfg.home;
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
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
          User = ollamaUser;
          Group = ollamaGroup;
        };

        unitConfig.RequiresMountsFor = cfg.home;
        wants = [ config.systemd.services.ollama.name ];
      };
      nginx.wants = [ config.systemd.services.open-webui.name ];
    };
  };
}
