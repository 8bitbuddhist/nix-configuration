{ config, lib, ... }:

let
  cfg = config.host.services.ssh;
in
{
  options = {
    host.services.ssh = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables SSH server.");
      ports = lib.mkOption {
        default = [ ];
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
