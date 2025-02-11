{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.vpn;
in
{
  options = {
    ${namespace}.services.vpn = {
      enable = lib.mkEnableOption "Creates a VPN connection on /dev/net/tun (via PIA).";
      auth = {
        password = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "Your PIA username.";
          example = "MySuperSecurePassword123";
        };
        user = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "The username for PIA.";
        };
      };
      countries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "List of countries to base the VPN out of.";
        default = [ "Netherlands" ];
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 0;
        description = "Any port to expose on the container.";
      };
      portForwarding.enable = lib.mkEnableOption "Enables port forwarding.";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.services.virtualization.containers.enable = true;
    virtualisation.oci-containers.containers.gluetun = {
      image = "qmcgaw/gluetun:v3";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--device=/dev/net/tun"
      ];
      environment = {
        VPN_SERVICE_PROVIDER = "private internet access";
        OPENVPN_USER = cfg.auth.user;
        OPENVPN_PASSWORD = cfg.auth.password;
        SERVER_REGIONS = (lib.strings.concatStringsSep "," cfg.countries);
        TZ = "America/New_York";
        VPN_PORT_FORWARDING = lib.mkIf cfg.portForwarding.enable "on";
      };
      ports = lib.mkIf (cfg.port > 0) [
        "127.0.0.1:${builtins.toString cfg.port}:${builtins.toString cfg.port}"
      ];
    };
  };
}
