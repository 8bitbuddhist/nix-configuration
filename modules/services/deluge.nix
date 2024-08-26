# This is an example of a blank module.
{ config, lib, ... }:

let
  cfg = config.aux.system.services.deluge;
in
{
  options = {
    aux.system.services.deluge = {
      autostart = lib.mkEnableOption "Automatically starts Deluge at boot.";
      enable = lib.mkEnableOption "Enables Deluge.";
      home = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Where to store Deluge's files";
      };
      domain = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The root domain that Deluge will be hosted on.";
        example = "example.com";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Deluge is hosted.";
        example = "https://deluge.example.com";
      };
    };

  };

  config = lib.mkIf cfg.enable {
    services = {
      nginx.virtualHosts."${cfg.url}" = {
        useACMEHost = cfg.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:8112";
          extraConfig = ''
            proxy_set_header X-Deluge-Base "/";
            add_header X-Frame-Options SAMEORIGIN;
          '';
        };
      };
      deluge = {
        enable = true;
        dataDir = cfg.home;
        web = {
          enable = true;
          openFirewall = false; # Not needed since we're using a reverse proxy
        };
      };
    };
  };
}
