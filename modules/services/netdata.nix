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
        apiKey = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "API key for streaming data from a child to a parent.";
        };
      };
      type = lib.mkOption {
        default = "parent";
        type = lib.types.enum [
          "parent"
          "child"
        ];
        description = "Whether this is a parent (default: includes web UI) or child (no web UI - streaming only).";
        example = "child";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Netdata is hosted.";
        example = "https://netdata.example.com";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable && cfg.type == "parent") {
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
          basicAuth = {
            "${cfg.auth.user}" = cfg.auth.password;
          };
          locations."/" = {
            proxyPass = "http://127.0.0.1:19999";
            extraConfig = ''
              # Taken from https://learn.netdata.cloud/docs/netdata-agent/configuration/running-the-netdata-agent-behind-a-reverse-proxy/nginx
              proxy_set_header X-Forwarded-Host $host;
              proxy_set_header X-Forwarded-Server $host;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              proxy_pass_request_headers on;
              proxy_set_header Connection "keep-alive";
              proxy_store off;
            '';
          };
        };

        netdata = {
          enable = true;
          package = pkgs.unstable.netdataCloud;
          enableAnalyticsReporting = false;
          configDir = {
            # Enable nvidia-smi: https://nixos.wiki/wiki/Netdata#nvidia-smi
            "python.d.conf" = pkgs.writeText "python.d.conf" ''
              nvidia_smi: yes
            '';
            # Allow incoming streams
            "stream.conf" = pkgs.writeText "stream.conf" ''
              [${config.secrets.services.netdata.apiKey}]
                enabled = yes
                default history = 3600
                default memory mode = dbengine
                health enabled by default = auto
                allow streaming from = *
            '';
          };
        };
      };
      systemd.services.nginx.wants = [ config.systemd.services.netdata.name ];
    })

    (lib.mkIf (cfg.enable && cfg.type == "child") {
      services.netdata = {
        enable = true;
        package = pkgs.unstable.netdataCloud;
        enableAnalyticsReporting = false;
        # Disable web UI
        config = {
          global = {
            "memory mode" = "none";
          };
          web = {
            mode = "none";
            "accept a streaming request every seconds" = 0;
          };
        };
        # Set up streaming
        configDir = {
          "stream.conf" = pkgs.writeText "stream.conf" ''
            [stream]
              enabled = yes
              destination = ${cfg.url}:443:SSL
              api key = ${cfg.auth.apiKey}
            [${cfg.auth.apiKey}]
              enabled = yes 
          '';
        };
      };
    })
  ];
}
