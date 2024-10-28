{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.services.webdav;

  port = 6065; # Internal port to run the server on
in
{
  options = {
    aux.system.services.webdav = {
      enable = lib.mkEnableOption "Enables Webdav server.";
      home = lib.mkOption {
        default = "/var/lib/webdav";
        type = lib.types.str;
        description = "Where to store Webdav's files";
        example = "/home/webdav";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Webdav is hosted.";
        example = "https://dav.example.com";
      };
      users = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.attrs;
        description = "List of user accounts to create.";
        example = lib.literalExpression "[ { username = \"user\"; password = \"pass\"; } ]";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      webdav = {
        enable = true;
        settings = {
          address = "127.0.0.1";
          port = port;
          scope = cfg.home;
          users = cfg.users;
        };
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = pkgs.util.getDomainFromURL cfg.url;
        forceSSL = true;
        locations."/".extraConfig = ''
          proxy_pass http://127.0.0.1:${builtins.toString port};
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header REMOTE-HOST $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header Host $host;
          proxy_redirect off;
        '';
      };
    };

    systemd.services = {
      webdav.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.webdav.name ];
    };
  };
}
