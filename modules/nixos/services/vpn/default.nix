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
      enable = lib.mkEnableOption "Creates a VPN connection on /dev/net/tun (via ProtonVPN).";
      privateKey = lib.mkOption {
        type = lib.types.str;
        description = "Wireguard private key.";
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
        VPN_SERVICE_PROVIDER = "protonvpn";
        VPN_TYPE = "wireguard";
        WIREGUARD_PRIVATE_KEY = cfg.privateKey;
        SERVER_COUNTRIES = (lib.strings.concatStringsSep "," cfg.countries);
        TZ = "America/New_York";
      };
      ports = lib.mkIf (cfg.port > 0) [ "${builtins.toString cfg.port}:${builtins.toString cfg.port}" ];
    };
  };
}
