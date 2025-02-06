{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.duplicacy-web;
in
{
  options = {
    ${namespace}.services.duplicacy-web = {
      enable = lib.mkEnableOption "Enables duplicacy-web";
      home = lib.mkOption {
        default = "/var/lib/duplicacy-web";
        type = lib.types.str;
        description = "Environment where duplicacy-web stores its config files";
      };
      port = lib.mkOption {
        default = 3875;
        type = lib.types.int;
        description = "The port to host duplicacy-web on.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.${namespace}.duplicacy-web ];

    # Install systemd service.
    systemd.services.duplicacy-web = {
      enable = true;
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      after = [
        "syslog.target"
        "network-online.target"
      ];
      description = "Start the Duplicacy backup service and web UI";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''${pkgs.${namespace}.duplicacy-web}/duplicacy-web'';
        Restart = "on-failure";
        RestartSec = 10;
        KillMode = "process";
      };
      environment = {
        HOME = cfg.home;
      };
      unitConfig.RequiresMountsFor = cfg.home;
    };
  };
}
