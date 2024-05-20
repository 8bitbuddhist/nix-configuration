{
  pkgs,
  config,
  lib,
  subdomains,
  ...
}:
let
  cfg = config.host.services.airsonic;
in
{
  options = {
    host.services.airsonic = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables Airsonic Advanced media streaming service.");
      home = lib.mkOption {
        type = lib.types.str;
        description = "Where to store Airsonic's files";
      };
      domain = lib.mkOption {
        type = lib.types.str;
        description = "FQDN for the host server";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    host.users.media.enable = true;
    users.users.airsonic.extraGroups = [ "media" ];

    services = {
      nginx.virtualHosts."music.${cfg.domain}" = {
        useACMEHost = cfg.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:4040";
          proxyWebsockets = true;
          extraConfig = "proxy_ssl_server_name on;";
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
      } // lib.optionalAttrs (cfg.home != null) { home = cfg.home; };
    };

    systemd.services = {
      airsonic.wantedBy = lib.mkForce [ ];
      nginx.wants = [ config.systemd.services.airsonic.name ];
    };
  };
}
