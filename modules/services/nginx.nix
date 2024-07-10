{ config, lib, ... }:

let
  cfg = config.aux.system.services.nginx;
in
{
  options = {
    aux.system.services.nginx = {
      autostart = lib.mkEnableOption (lib.mdDoc "Whether to autostart Nginx at boot.");
      enable = lib.mkEnableOption (lib.mdDoc "Enable the Nginx web server.");

      virtualHosts = lib.mkOption {
        default = { };
        type = lib.types.attrs;
        description = "Virtualhost configurations for Nginx.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;

      # Use recommended settings per https://wiki.nixos.org/wiki/Nginx#Hardened_setup_with_TLS_and_HSTS_preloading
      recommendedGzipSettings = true;
      recommendedOptimisation = true;
      recommendedTlsSettings = true;

      virtualHosts = cfg.virtualHosts;
    };

    # Open ports
    networking.firewall = {
      enable = true;
      allowedTCPPorts = [
        80
        443
      ];
    };

    # Disable autostart if configured
    systemd.services.nginx = lib.mkIf (!cfg.autostart) { wantedBy = lib.mkForce [ ]; };
  };
}
