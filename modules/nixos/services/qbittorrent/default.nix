{
  config,
  lib,
  pkgs,
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
        type = lib.types.str;
        default = "8080";
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
      vpn = {
        enable = lib.mkEnableOption "Enables a VPN.";
        privateKey = lib.mkOption {
          type = lib.types.str;
          description = "Wireguard private key.";
        };
        countries = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "List of countries to base the VPN out of.";
          default = [ "Netherlands" ];
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${cfg.port}";
          extraConfig = ''
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Forwarded-Host $host;
            proxy_set_header   X-Forwarded-Server $host;
            proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
          '';
        };
      };
    };

    virtualisation = {
      podman.autoPrune.enable = true;
      oci-containers.containers = {
        qbittorrent = {
          image = "lscr.io/linuxserver/qbittorrent:latest";
          environment = {
            PUID = (builtins.toString UID);
            PGID = (builtins.toString GID);
            WEBUI_PORT = "${cfg.port}";
          };
          volumes = [
            "${cfg.home}:/config"
            "${cfg.home}/qBittorrent/downloads:/downloads"
          ];
          # Forward ports to gluetun if VPN is enabled. Otherwise, open ports directly
          extraOptions = lib.mkIf cfg.vpn.enable [ "--network=container:gluetun" ];
          dependsOn = lib.mkIf cfg.vpn.enable [ "gluetun" ];
          ports = lib.mkIf (!cfg.vpn.enable) [ "${cfg.port}:${cfg.port}" ];
        };

        gluetun = lib.mkIf cfg.vpn.enable {
          image = "qmcgaw/gluetun:v3";
          extraOptions = [
            "--cap-add=NET_ADMIN"
            "--device=/dev/net/tun"
          ];
          environment = {
            VPN_SERVICE_PROVIDER = "protonvpn";
            VPN_TYPE = "wireguard";
            WIREGUARD_PRIVATE_KEY = config.${namespace}.secrets.services.protonvpn.privateKey;
            SERVER_COUNTRIES = (lib.strings.concatStringsSep "," cfg.vpn.countries);
            TZ = "America/New_York";
          };
          ports = [ "${cfg.port}:${cfg.port}" ];
        };
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

    systemd.services.nginx.wants = [ config.systemd.services.podman-qbittorrent.name ];
  };
}
