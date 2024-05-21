{
  pkgs,
  config,
  lib,
  ...
}:
let
  subdomain = "code";
  cfg = config.host.services.forgejo;

  cli-cfg = config.services.forgejo;

  forgejo-cli = pkgs.writeScriptBin "forgejo-cli" ''
    #!${pkgs.runtimeShell}
    cd ${cli-cfg.stateDir}
    sudo=exec
    if [[ "$USER" != forgejo ]]; then
      sudo='exec /run/wrappers/bin/sudo -u ${cli-cfg.user} -g ${cli-cfg.group} --preserve-env=GITEA_WORK_DIR --preserve-env=GITEA_CUSTOM'
    fi
    # Note that these variable names will change
    export GITEA_WORK_DIR=${cli-cfg.stateDir}
    export GITEA_CUSTOM=${cli-cfg.customDir}
    $sudo ${lib.getExe cli-cfg.package} "$@"
  '';
in
{
  options = {
    host.services.forgejo = {
      autostart = lib.mkEnableOption (lib.mdDoc "Automatically starts Forgejo at boot.");
      enable = lib.mkEnableOption (lib.mdDoc "Enables Forgejo Git hosting service.");
      home = lib.mkOption {
        type = lib.types.str;
        description = "Where to store Forgejo's files";
      };
      domain = lib.mkOption {
        type = lib.types.str;
        description = "FQDN for the host server";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ forgejo-cli ];
    services = {
      nginx.virtualHosts."${subdomain}.${cfg.domain}" = {
        useACMEHost = cfg.domain;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:3000";
          proxyWebsockets = true;
          extraConfig = "proxy_ssl_server_name on;"; # required when the target is also TLS server with multiple hosts
        };
      };

      forgejo = {
        enable = true;
        lfs.enable = true;
        settings.server = {
          DOMAIN = "${config.secrets.networking.primaryDomain}";
          ROOT_URL = "https://code.${config.secrets.networking.primaryDomain}/";
          HTTP_PORT = 3000;
        };
        useWizard = true;
      } // lib.optionalAttrs (cfg.home != null) { stateDir = cfg.home; };
    };

    systemd.services = {
      nginx.wants = [ config.systemd.services.forgejo.name ];
    } // lib.optionalAttrs (!cfg.autostart) { forgejo.wantedBy = lib.mkForce [ ]; };
  };
}
