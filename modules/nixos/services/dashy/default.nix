{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.services.dashy;
in
{
  options = {
    ${namespace}.services.dashy = {
      enable = lib.mkEnableOption "Enables the Dashy homepage dashboard.";
      home = lib.mkOption {
        default = "/var/lib/dashy";
        type = lib.types.str;
        description = "Where to store Dashy's files";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Dashy is hosted.";
        example = "https://example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # FIXME: Setup Dashy
    services.dashy = {
      enable = true;
    };

    systemd.services = {
      dashy = {
        unitConfig.RequiresMountsFor = cfg.home;
      };
      nginx.wants = [ config.systemd.services.dashy.name ];
    };
  };
}
