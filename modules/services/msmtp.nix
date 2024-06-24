# See https://nixos.wiki/wiki/Msmtp
{ config, lib, ... }:

let
  cfg = config.aux.system.services.msmtp;
in
with lib;
{
  options = {
    aux.system.services.msmtp.enable = mkEnableOption (mdDoc "Enables mail server");
  };

  config = mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      accounts.default = {
        host = config.secrets.services.msmtp.host;
        user = config.secrets.services.msmtp.user;
        password = config.secrets.services.msmtp.password;
        auth = true;
        tls = true;
        tls_starttls = true;
        port = 587;
        from = "${config.networking.hostName}@${config.secrets.networking.primaryDomain}";
        to = config.secrets.users.aires.email;
      };
    };
  };
}
