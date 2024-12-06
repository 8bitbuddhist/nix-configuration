# See https://wiki.nixos.org/wiki/Msmtp
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.msmtp;
in
{
  options = {
    ${namespace}.services.msmtp = {
      enable = lib.mkEnableOption "Enables mail server";
      accounts = lib.mkOption {
        type = lib.types.attrs;
        description = "A list of accounts to use for msmtp.";
      };
      aliases = lib.mkOption {
        default = { };
        type = lib.types.attrs;
        description = "Optional email aliases to add.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.msmtp = {
      enable = true;
      defaults.aliases = "/etc/aliases";
      accounts = cfg.accounts;
    };

    # Send all mail to my email address by default
    environment.etc."aliases" = cfg.aliases;
  };
}
