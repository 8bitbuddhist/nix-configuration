{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.aux.system.services.duplicacy-web;
  duplicacy-web = pkgs.callPackage ../../packages/duplicacy-web.nix { inherit pkgs lib; };
in
{
  options = {
    aux.system.services.duplicacy-web = {
      enable = lib.mkEnableOption "Enables duplicacy-web";
      environment = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Environment where duplicacy-web stores its config files";
      };
      requires = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        description = "If this service depends on other systemd units (e.g. a *.mount unit), enter their name(s) here.";
        example = [ "storage.mount" ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = [ duplicacy-web ];

    networking.firewall.allowedTCPPorts = [ 3875 ];

    # Install systemd service.
    systemd.services.duplicacy-web = {
      enable = true;
      wants = [ "network-online.target" ];
      after = [
        "syslog.target"
        "network-online.target"
      ];
      description = "Start the Duplicacy backup service and web UI";
      serviceConfig = {
        Type = "simple";
        ExecStart = ''${duplicacy-web}/duplicacy-web'';
        Restart = "on-failure";
        RestartSrc = 10;
        KillMode = "process";
      };
      environment = {
        HOME = cfg.environment;
      };
    } // lib.optionalAttrs (cfg.requires != [ ]) { requires = cfg.requires; };
  };
}
