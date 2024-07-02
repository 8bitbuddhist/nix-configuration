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
with lib;
rec {
  options = {
    aux.system.services.duplicacy-web = {
      enable = mkEnableOption (mdDoc "Enables duplicacy-web");
      autostart = mkOption {
        default = true;
        type = types.bool;
        description = "Whether to auto-start duplicacy-web on boot";
      };

      environment = mkOption {
        default = "";
        type = types.str;
        description = "Environment where duplicacy-web stores its config files";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      nixpkgs.config.allowUnfree = true;
      environment.systemPackages = [ duplicacy-web ];

      networking.firewall.allowedTCPPorts = [ 3875 ];

      # Install systemd service.
      systemd.services."duplicacy-web" = {
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
      };
    })

    (lib.mkIf (!cfg.autostart) {
      # Disable autostart if needed
      systemd.services.duplicacy-web.wantedBy = lib.mkForce [ ];
    })
  ];

}
