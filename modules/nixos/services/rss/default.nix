{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.rss;
in
{
  options = {
    ${namespace}.services.rss = {
      enable = lib.mkEnableOption "Enables RSS hosting service via FreshRSS.";
      auth = {
        password = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "The password to use for the default user.";
          example = "MySuperSecurePassword123";
        };
        user = lib.mkOption {
          default = "ltuser";
          type = lib.types.str;
          description = "The username to use for the default user.";
        };
      };
      home = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Where to store FreshRSS's files";
        example = "/home/freshrss";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where FreshRSS is hosted.";
        example = "https://rss.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      freshrss = {
        enable = true;
        baseUrl = "https://${cfg.url}";
        dataDir = cfg.home;
        defaultUser = cfg.auth.user;
        passwordFile = pkgs.writeText "rss-defaultpassword" ''
          ${cfg.auth.password}
        '';
        authType = "form";
        database.type = "sqlite";

        virtualHost = cfg.url;
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
      };
    };

    systemd.services = {
      freshrss.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.freshrss.name ];
    };
  };
}
