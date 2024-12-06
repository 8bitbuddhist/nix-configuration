{ config, lib, ... }:

let
  cfg = config.aux.system.services.ssh;
in
{
  options = {
    aux.system.services.ssh = {
      enable = lib.mkEnableOption "Enables SSH server.";
      ports = lib.mkOption {
        default = [ 22 ];
        type = lib.types.listOf lib.types.int;
        description = "Ports for SSH to listen on.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      ports = cfg.ports;

      settings = {
        # require public key authentication and disable root logins
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PubkeyAuthentication = true;
        PermitRootLogin = "no";
      };
    };
  };
}
