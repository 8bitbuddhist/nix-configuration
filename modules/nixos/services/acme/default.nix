{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.acme;
in
{
  options = {
    ${namespace}.services.acme = {
      enable = lib.mkEnableOption "Enable the ACME client (for Let's Encrypt TLS certificates).";
      certs = lib.mkOption {
        default = { };
        type = lib.types.attrs;
        description = "Cert configurations for ACME.";
      };
      defaultEmail = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Default admin email to use for problems.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.defaultEmail;
      certs = cfg.certs;
    };

    # /var/lib/acme/.challenges must be writable by the ACME user
    # and readable by the Nginx user. The easiest way to achieve
    # this is to add the Nginx user to the ACME group.
    users.users.nginx.extraGroups = lib.mkIf config.${namespace}.services.nginx.enable [ "acme" ];
  };
}
