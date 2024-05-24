# Serves a binary cache for Nix packages
{ config, lib, ... }:

let
  cfg = config.host.services.cache;
in
{
  options = {
    host.services.cache = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables binary cache hosting.");
      secretKeyFile = lib.mkOption {
        default = "/var/cache-priv-key.pem";
        type = lib.types.str;
        description = "Where the signing key lives.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services = {
      nix-serve = {
        enable = true;
        secretKeyFile = cfg.privateKeyFile;
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
  };
}
