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
    aux.system.services.boinc.enable = lib.mkEnableOption (
      lib.mdDoc "Enables BOINC distributed computing service."
    );
  };

  config = lib.mkIf cfg.enable {
    services.boinc = {
      enable = true;
      package = pkgs.boinc-headless;
      dataDir = "/var/lib/boinc";
      extraEnvPackages = [ pkgs.ocl-icd ];
      allowRemoteGuiRpc = true;
    };

    # Allow connections via BOINC Manager
    networking.firewall.allowedTCPPorts = [ 31416 ];
  };
}
