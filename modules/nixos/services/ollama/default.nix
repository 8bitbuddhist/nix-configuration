{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.ollama;

  api.port = 11434;
  webui.port = 8130;
in
{
  options = {
    ${namespace}.services.ollama = {
      enable = lib.mkEnableOption "Enables Ollama.";
      auth = {
        password = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "The password to use for authentication.";
          example = "MySuperSecurePassword123";
        };
        user = lib.mkOption {
          default = "ltuser";
          type = lib.types.str;
          description = "The username to use for authentication.";
        };
      };
      home = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Where to store Ollama's files";
        example = "/var/lib/ollama";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Ollama is hosted.";
        example = "https://ollama.example.com";
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
        home = cfg.home;
      };

      open-webui = {
        enable = true;
        port = webui.port;
        environment = {
          ANONYMIZED_TELEMETRY = "False";
          DO_NOT_TRACK = "True";
          SCARF_NO_ANALYTICS = "True";
          OLLAMA_API_BASE_URL = "http://127.0.0.1:${
            builtins.toString config.${namespace}.services.ollama.port
          }";
        };
        stateDir = "${cfg.home}/open-webui";
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
        basicAuth = {
          "${cfg.auth.user}" = cfg.auth.password;
        };
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString api.port}";
          extraConfig = "proxy_ssl_server_name on;";
        };
      };
    };

    systemd.services = {
      ollama.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.ollama.name ];
    };
  };
}
