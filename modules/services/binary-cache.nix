{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.services.binary-cache;
in
{
  options = {
    aux.system.services.binary-cache = {
      enable = lib.mkEnableOption "Enable a binary cache hosting service.";
      home = lib.mkOption {
        default = "/var/lib/nix-binary-cache";
        type = lib.types.str;
        description = "Where to store the binary cache and its config files.";
      };
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
        useACMEHost = pkgs.util.getDomainFromURL cfg.url;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
        };
      };
    };
  };
}
