{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.services.qbittorrent;
  UID = 850;
  GID = 850;
  package = pkgs.qbittorrent-nox;
  port = 8080;
in
{
  options = {
    aux.system.services.qbittorrent = {
      enable = lib.mkEnableOption "Enables qBittorrent.";
      home = lib.mkOption {
        default = "/var/lib/qbittorrent";
        type = lib.types.str;
        description = "Where to store qBittorrent's files";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where qBittorrent is hosted.";
        example = "https://qbittorrent.example.com";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "qbittorrent";
        description = "User account under which qBittorrent runs.";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "qbittorrent";
        description = "Group under which qBittorrent runs.";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = pkgs.util.getDomainFromURL cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8080";
          extraConfig = ''
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-Host $host;
            proxy_set_header   X-Forwarded-Server $host;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };

    systemd.services.qbittorrent = {
      # based on the plex.nix service module and
      # https://github.com/qbittorrent/qBittorrent/blob/master/dist/unix/systemd/qbittorrent-nox%40.service.in
      description = "qBittorrent service";
      documentation = [ "man:qbittorrent-nox(1)" ];
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.RequiresMountsFor = cfg.home;

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;

        # Run the pre-start script with full permissions (the "!" prefix) so it
        # can create the data directory if necessary.
        ExecStartPre =
          let
            preStartScript = pkgs.writeScript "qbittorrent-run-prestart" ''
              #!${pkgs.bash}/bin/bash

              # Create data directory if it doesn't exist
              if ! test -d "$QBT_PROFILE"; then
                echo "Creating initial qBittorrent data directory in: $QBT_PROFILE"
                install -d -m 0755 -o "${cfg.user}" -g "${cfg.group}" "$QBT_PROFILE"
              fi
            '';
          in
          "!${preStartScript}";
        ExecStart = "${package}/bin/qbittorrent";
      };

      environment = {
        QBT_PROFILE = cfg.home;
        QBT_WEBUI_PORT = toString port;
      };
    };

    users = {
      users.${cfg.user} = {
        description = "qBittorrent user";
        isNormalUser = false;
        group = cfg.group;
        uid = UID;
      };
      groups.${cfg.group}.gid = GID;
    };

    systemd.services.nginx.wants = [ config.systemd.services.qbittorrent.name ];
  };
}
