{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.services.airsonic;
in
{
  options = {
    aux.system.services.airsonic = {
      enable = lib.mkEnableOption "Enables Airsonic Advanced media streaming service.";
      home = lib.mkOption {
        default = "/var/lib/airsonic";
        type = lib.types.str;
        description = "Where to store Airsonic's files";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Airsonic is hosted.";
        example = "https://forgejo.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    aux.system.users.media.enable = true;
    users.users.airsonic.extraGroups = [ "media" ];

    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = pkgs.util.getDomainFromURL cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:4040";
          proxyWebsockets = true;
          extraConfig = ''
            # Taken from https://airsonic.github.io/docs/proxy/nginx/
            proxy_set_header X-Real-IP         $remote_addr;
            proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto https;
            proxy_set_header X-Forwarded-Host  $host;
            proxy_set_header Host              $host;
            proxy_max_temp_file_size           0;
            proxy_ssl_server_name on;
          '';
        };
      };

      airsonic = {
        enable = true;
        war = "${
          (pkgs.callPackage ../../packages/airsonic-advanced.nix { inherit lib; })
        }/webapps/airsonic.war";
        port = 4040;
        jre = pkgs.jdk17;
        jvmOptions = [
          "-Dserver.use-forward-headers=true"
          "-Xmx4G" # Increase Java heap size to 4GB
        ];
      } // lib.optionalAttrs (cfg.home != "") { home = cfg.home; };
    };

    systemd.services = {
      airsonic.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.airsonic.name ];
    };
  };
}
