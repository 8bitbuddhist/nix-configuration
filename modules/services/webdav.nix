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
          behindProxy = true;
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

    environment.etc = lib.mkIf config.services.fail2ban.enable {
      "fail2ban/filter.d/webdav.conf".text = ''
        [INCLUDES]
        before = common.conf

        [Definition]
        # Failregex to match "invalid password" and extract remote_address only
        failregex = ^.*invalid password\s*\{.*"remote_address":\s*"<HOST>"\s*\}

        # Failregex to match "invalid username" and extract remote_address only (if applicable)
        failregex += ^.*invalid username\s*\{.*"remote_address":\s*"<HOST>"\s*\}

        ignoreregex =
      '';

      "fail2ban/jail.d/webdav.conf".text = ''
        [webdav]
        enabled = true
        port = ${builtins.toString port}
        filter = webdav
        logpath = /var/log/webdav/fail2ban.log
        banaction = iptables-allports
        ignoreself = false
      '';
    };

    systemd.services = {
      webdav.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.webdav.name ];
    };
  };
}
