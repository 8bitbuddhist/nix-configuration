{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.qbittorrent;
  UID = 850;
  GID = 850;
in
{
  options = {
    ${namespace}.services.qbittorrent = {
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
      port = lib.mkOption {
        type = lib.types.int;
        default = 8080;
        description = "The port to host qBittorrent on.";
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
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
          extraConfig = ''
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-Host $host;
            proxy_set_header   X-Forwarded-Server $host;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };

    ${namespace}.services.virtualization.containers.enable = true;

    virtualisation.oci-containers.containers = {
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent:latest";
        environment = {
          PUID = (builtins.toString UID);
          PGID = (builtins.toString GID);
          WEBUI_PORT = "${builtins.toString cfg.port}";
        };
        volumes = [
          "${cfg.home}:/config"
          "${cfg.home}/qBittorrent/downloads:/downloads"
        ];
        # Forward ports to gluetun if VPN is enabled. Otherwise, open ports directly
        extraOptions = lib.mkIf config.${namespace}.services.vpn.enable [ "--network=container:gluetun" ];
        dependsOn = lib.mkIf config.${namespace}.services.vpn.enable [ "gluetun" ];
        ports = lib.mkIf (!config.${namespace}.services.vpn.enable) [
          "127.0.0.1:${builtins.toString cfg.port}:${builtins.toString cfg.port}"
        ];
      };

      # Allow Gluetun to update qBittorrent when the VPN port changes.
      # See https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/vpn-port-forwarding.md#qbittorrent-example
      gluetun.environment = lib.mkIf config.${namespace}.services.vpn.enable {
        VPN_PORT_FORWARDING_UP_COMMAND = "/bin/sh -c 'wget -O- --retry-connrefused --post-data \"json={\"listen_port\":{{PORTS}}}\" http://127.0.0.1:${builtins.toString cfg.port}/api/v2/app/setPreferences 2>&1'";
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

    systemd.services = {
      qbittorrent.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.podman-qbittorrent.name ];
    };
  };
}
