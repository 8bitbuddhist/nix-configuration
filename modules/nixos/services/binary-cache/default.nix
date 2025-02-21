{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.binary-cache;
in
{
  options = {
    ${namespace}.services.binary-cache = {
      enable = lib.mkEnableOption "Enable a binary cache hosting service.";
      secretKeyFile = lib.mkOption {
        default = "/var/lib/nix-binary-cache/privkey.pem";
        type = lib.types.str;
        description = "Where to find the binary cache's private key.";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where the cache is hosted.";
        example = "https://cache.example.com";
      };
      auth = {
        password = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "The password to use for basic authentication for the cache.";
          example = "MySuperSecurePassword123";
        };
        user = lib.mkOption {
          default = "cache-user";
          type = lib.types.str;
          description = "The username to use for basic auth.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      nix-serve = {
        enable = true;
        secretKeyFile = cfg.secretKeyFile;
        bindAddress = "127.0.0.1";
      };

      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = lib.${namespace}.getDomainFromURI cfg.url;
        forceSSL = true;
        basicAuth = {
          "${cfg.auth.user}" = cfg.auth.password;
        };
        locations."/" = {
          proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
        };
      };
    };

    systemd.services = {
      nix-serve.unitConfig.RequiresMountsFor = cfg.secretKeyFile;
      nginx.wants = [ config.systemd.services.nix-serve.name ];
    };
  };
}
