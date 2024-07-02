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
      autostart = lib.mkEnableOption (lib.mdDoc "Automatically starts Airsonic at boot.");
      enable = lib.mkEnableOption (lib.mdDoc "Enables Airsonic Advanced media streaming service.");
      home = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Where to store Airsonic's files";
      };
      domain = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The root domain that Airsonic will be hosted on.";
        example = "example.com";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Airsonic is hosted.";
        example = "https://forgejo.example.com";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      aux.system.users.media.enable = true;
      users.users.airsonic.extraGroups = [ "media" ];

      services = {
        nginx.virtualHosts."${cfg.url}" = {
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
        } // lib.optionalAttrs (cfg.home != "") { home = cfg.home; };
      };

      systemd.services.nginx.wants = [ config.systemd.services.airsonic.name ];
    })
    (lib.mkIf (!cfg.autostart) {
      # Disable autostart if needed
      systemd.services.airsonic.wantedBy = lib.mkForce [ ];
    })
  ];
}
