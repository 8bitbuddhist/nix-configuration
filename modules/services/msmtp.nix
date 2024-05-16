# See https://nixos.wiki/wiki/Msmtp
{
  config,
  lib,
  nix-secrets,
  ...
}:

let
  cfg = config.host.services.msmtp;
in
with lib;
{
  options = {
    host.services.msmtp.enable = mkEnableOption (mdDoc "Enables mail server");
  };

  config = mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      accounts.default = {
        host = nix-secrets.services.msmtp.host;
        user = nix-secrets.services.msmtp.user;
        password = nix-secrets.services.msmtp.password;
        auth = true;
        tls = true;
        tls_starttls = true;
        port = 587;
        from = "${config.networking.hostName}@${nix-secrets.networking.primaryDomain}";
        to = nix-secrets.users.aires.email;
      };
    };
  };
}
