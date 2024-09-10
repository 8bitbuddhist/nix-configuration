{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.services.transmission;
in
{
  options = {
    aux.system.services.transmission = {
      enable = lib.mkEnableOption "Enables Transmission.";
      home = lib.mkOption {
        default = "/var/lib/transmission";
        type = lib.types.str;
        description = "Where to store Transmission's files";
      };
      auth = {
        user = lib.mkOption {
          default = "transmission";
          type = lib.types.str;
          description = "Username for basic auth.";
        };
        password = lib.mkOption {
          default = "transmission";
          type = lib.types.str;
          description = "Password for basic auth.";
        };
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Transmission is hosted.";
        example = "https://transmission.example.com";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = pkgs.util.getDomainFromURL cfg.url;
        forceSSL = true;
        basicAuth = {
          "${cfg.auth.user}" = cfg.auth.password;
        };
        locations."/" = {
          proxyPass = "http://127.0.0.1:9091";
          extraConfig = ''
            proxy_pass_header  X-Transmission-Session-Id;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-Host $host;
            proxy_set_header   X-Forwarded-Server $host;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
            add_header         X-Frame-Options SAMEORIGIN;
            add_header         Front-End-Https   on;
          '';
        };
      };
      transmission = {
        enable = true;
        home = cfg.home;
        downloadDirPermissions = "770"; # Required. See https://github.com/NixOS/nixpkgs/issues/183429#issuecomment-1648371683
      };
    };

    systemd.services = {
      transmission.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.transmission.name ];
    };
  };
}
