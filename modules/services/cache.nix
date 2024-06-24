# Serves a binary cache for Nix packages
{
  config,
  lib,
  self,
  ...
}:

let
  cfg = config.aux.system.services.cache;
in
{
  options = {
    aux.system.services.cache = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables binary cache hosting.");
      secretKeyFile = lib.mkOption {
        default = "/var/cache-priv-key.pem";
        type = lib.types.str;
        description = "Where the signing key lives.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable cache service
    services = {
      nix-serve = {
        enable = true;
        secretKeyFile = cfg.secretKeyFile;
      };

      nginx.virtualHosts."${config.secrets.services.cache.url}" = {
        useACMEHost = config.secrets.networking.primaryDomain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
          extraConfig = "proxy_ssl_server_name on;";
        };
      };
    };

    nix.settings = {
      extra-substituters = [ "ssh://${config.secrets.services.cache.url}" ];
      trusted-public-keys = [
        "${config.secrets.services.cache.url}:mTYvveYNhoXttGOxJj2uP0MQ/ZPJce5hY+xSvOxswls=%"
      ];
    };

    # Run nightly builds for certain targets
    systemd.timers."nix-distributed-build-timer" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = "true";
        Unit = "nix-distributed-build.service";
      };
    };

    systemd.services."nix-distributed-build" = {
      # Add target names below as a new line
      script = ''
        set -eu
        nh os build --update --hostname Khanda
      '';
      serviceConfig = {
        Type = "oneshot";
        User = config.users.users.aires.name;
      };
    };
  };
}
