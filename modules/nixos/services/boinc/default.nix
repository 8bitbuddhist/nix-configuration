{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.services.boinc;
in
{
  options = {
    aux.system.services.boinc = {
      enable = lib.mkEnableOption "Enables BOINC distributed computing service.";
      home = lib.mkOption {
        default = "/var/lib/boinc";
        type = lib.types.str;
        description = "Where to store BOINC's files";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.boinc = {
      enable = true;
      package = pkgs.boinc-headless;
      dataDir = cfg.home;
      extraEnvPackages = [
        pkgs.ocl-icd
      ] ++ lib.optionals config.aux.system.gpu.nvidia.enable [ pkgs.linuxPackages.nvidia_x11 ];
      allowRemoteGuiRpc = true;
    };

    systemd.services.boinc.unitConfig.RequiresMountsFor = cfg.home;

    # Allow connections via BOINC Manager
    networking.firewall.allowedTCPPorts = [ 31416 ];
  };
}
