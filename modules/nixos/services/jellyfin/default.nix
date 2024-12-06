{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.jellyfin;

  jellyfin-audio-save = pkgs.unstable.jellyfin.overrideAttrs (
    finalAttrs: prevAttrs: { patches = [ ./jellyfin-audio-save-position.patch ]; }
  );
in
{
  options = {
    ${namespace}.services.jellyfin = {
      enable = lib.mkEnableOption "Enables the Jellyfin media streaming service.";
      home = lib.mkOption {
        default = "/var/lib/jellyfin";
        type = lib.types.str;
        description = "Where to store Jellyfin's files";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Jellyfin is hosted.";
        example = "https://jellyfin.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.users.media.enable = true;

    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.Sapana.getDomainFromURI cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true;
          extraConfig = ''
            # Taken from https://jellyfin.org/docs/general/networking/nginx/
             client_max_body_size 20M;
                        
            # Security / XSS Mitigation Headers
            # NOTE: X-Frame-Options may cause issues with the webOS app
            add_header X-Frame-Options "SAMEORIGIN";
            add_header X-Content-Type-Options "nosniff";

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Protocol $scheme;
            proxy_set_header X-Forwarded-Host $host;

            # Disable buffering when the nginx proxy gets very resource heavy upon streaming
            proxy_buffering off;
          '';
        };
        locations."/socket" = {
          proxyPass = "http://127.0.0.1:8096";
          proxyWebsockets = true;
          extraConfig = ''
            # Proxy Jellyfin Websockets traffic
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header X-Forwarded-Protocol $scheme;
            proxy_set_header X-Forwarded-Host $host;
          '';
        };
      };

      jellyfin = {
        enable = true;
        dataDir = cfg.home;
        group = "media";
        package = jellyfin-audio-save;
      };
    };

    systemd.services = {
      jellyfin = {
        # Install packages for plugins
        path = with pkgs; [
          id3v2
          yt-dlp
        ];
        unitConfig.RequiresMountsFor = cfg.home;
      };
      nginx.wants = [ config.systemd.services.jellyfin.name ];
    };

    # Set permissions for media folders
    systemd.tmpfiles.rules = [ "Z /storage/Media 6775 aires media - -" ];
  };
}
