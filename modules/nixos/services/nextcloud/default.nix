{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.services.nextcloud;
in
{
  options = {
    ${namespace}.services.nextcloud = {
      enable = lib.mkEnableOption "Enables the Nextcloud groupware service.";
      home = lib.mkOption {
        default = "/var/lib/nextcloud";
        type = lib.types.str;
        description = "Where to store Nextcloud's files";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Nextcloud is hosted.";
        example = "https://nextcloud.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      nextcloud = {
        enable = true;
        home = cfg.home;
        hostName = cfg.url;
        https = true;
        appstoreEnable = true;
        maxUploadSize = "10G";
        nginx.recommendedHttpHeaders = true;
        # Automatically update apps nightly
        autoUpdateApps = {
          enable = true;
          startAt = "04:00";
        };

        # Set default admin password
        config.adminpassFile = "${pkgs.writeText "nextcloud-default-pass" ''
          ${config.${namespace}.secrets.services.defaultPassword}
        ''}";

        settings = {
          # Add additional previewers here, e.g. for HEIC images
          enabledPreviewProviders = lib.mkAfter [
            "OC\\Preview\\HEIC"
          ];

          # Enable mail delivery. See https://wiki.nixos.org/wiki/Nextcloud#Mail_delivery
          mail_smtpmode = "sendmail";
          mail_sendmailmode = "pipe";
        };
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
      };
    };

    systemd.services = {
      nextcloud.unitConfig.RequiresMountsFor = cfg.home;
      nginx.wants = [ config.systemd.services.nextcloud.name ];
    };
  };
}
