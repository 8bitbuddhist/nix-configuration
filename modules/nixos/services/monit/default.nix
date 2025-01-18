# Starting template: https://dschrempf.github.io/linux/2024-02-14-monitoring-a-home-server/
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.monit;

  port = 2812;
in
{
  options = {
    ${namespace}.services.monit = {
      enable = lib.mkEnableOption "Enable Monit monitoring service.";

      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Monit is hosted.";
        example = "https://monit.example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      monit = {
        enable = true;
        config = lib.strings.concatStringsSep "\n" [
          # General settings
          ''
            set daemon 60
            set httpd port ${builtins.toString port}
                allow localhost
          ''

          # Check host CPU/RAM/swap usage
          ''
            check system $HOST
                if loadavg (15min) > 4 for 5 times within 15 cycles then alert
                if memory usage > 80% for 4 cycles then alert
                if swap usage > 80% for 4 cycles then alert
          ''

          # Monitor filesystems
          ''
            check filesystem root with path /
              if space usage > 80% then alert
            check filesystem storage with path /storage
              if space usage > 75% then alert
          ''

          # Monitor RAID array
          ''
            check program raid-Sapana with path "/run/current-system/sw/bin/mdadm --misc --detail --test /dev/md/Sapana"
              if status != 0 then alert
          ''

          # Send emails using MSMTP
          ''
              set mailserver localhost
              set mail-format {
                from: admin@${lib.${namespace}.getDomainFromURI cfg.url}
                subject: $SERVICE $EVENT at $DATE
                message: Monit $ACTION $SERVICE at $DATE on $HOST: $DESCRIPTION.
            } ''
        ];
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:${builtins.toString port}";
          extraConfig = "proxy_ssl_server_name on;";
        };
      };
    };

    systemd.services.nginx.wants = [ config.systemd.services.monit.name ];
  };
}
