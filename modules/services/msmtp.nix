# See https://wiki.nixos.org/wiki/Msmtp
{ config, lib, ... }:

let
  cfg = config.aux.system.services.msmtp;
in
{
  options = {
    aux.system.services.msmtp.enable = lib.mkEnableOption "Enables mail server";
  };

  config = lib.mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      defaults.aliases = "/etc/aliases";
      accounts.default = {
        host = config.secrets.services.msmtp.host;
        user = config.secrets.services.msmtp.user;
        password = config.secrets.services.msmtp.password;
        auth = true;
        tls = true;
        tls_starttls = true;
        port = 587;
        from = "${config.networking.hostName}@${config.secrets.networking.domains.primary}";
      };
    };

    # Send all mail to my email address by default
    environment.etc."aliases" = {
      text = ''
        default: ${config.secrets.users.aires.email}
      '';
      mode = "0644";
    };
  };
}
