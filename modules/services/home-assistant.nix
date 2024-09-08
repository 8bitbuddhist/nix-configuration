{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.services.home-assistant;
in
{
  options = {
    aux.system.services.home-assistant = {
      enable = lib.mkEnableOption "Enables Home Assistant.";
      domain = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The root domain that Home Assistant will be hosted on.";
        example = "example.com";
      };
      home = lib.mkOption {
        default = "/etc/home-assistant";
        type = lib.types.str;
        description = "Where to store Home Assistant's files";
        example = "/home/home-assistant";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Home Assistant is hosted.";
        example = "https://home-assistant.example.com";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    services = {
      home-assistant = {
        enable = true;
        # opt-out from declarative configuration management
        lovelaceConfig = null;
        # configure the path to your config directory
        configDir = cfg.home;
        # specify list of components required by your configuration
        extraComponents = [
          "default_config"
          "esphome"
          "eufy"
          "govee_light_local"
          "met"
          "radio_browser"
          "tplink"
        ];
        extraPackages = python3Packages: with python3Packages; [ numpy ];
        config.http = {
          server_host = "::1";
          trusted_proxies = [ "::1" ];
          use_x_forwarded_for = true;
        };
      };
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = cfg.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://[::1]:8123";
          proxyWebsockets = true;
          extraConfig = ''
            # Security / XSS Mitigation Headers
            add_header X-Frame-Options "SAMEORIGIN";
            add_header X-Content-Type-Options "nosniff";

            proxy_ssl_server_name on;
            proxy_set_header Host $host;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Real-IP $remote_addr;

            proxy_buffering off;
          '';
        };
      };
    };

    systemd.services = {
      home-assistant.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.home-assistant.name ];
    };
  };
}
