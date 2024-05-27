{
  pkgs,
  config,
  lib,
  ...
}:
let
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
        default = "";
        type = lib.types.str;
        description = "Where to store Forgejo's files";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      forgejo-cli
      pkgs.podman-tui
    ];
    services = {
      nginx.virtualHosts."${config.secrets.services.forgejo.url}" = {
        useACMEHost = config.secrets.networking.primaryDomain;
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

      # Enable runner for CI actions
      gitea-actions-runner = {
        package = pkgs.forgejo-actions-runner;
        instances.default = {
          enable = true;
          name = config.networking.hostName;
          url = "https://${config.secrets.services.forgejo.url}";
          token = config.secrets.services.forgejo.runner-token;
          labels = [
            "nix:docker://nixos/nix" # Shoutout to Icewind 1991 for this syntax: https://icewind.nl/entry/gitea-actions-nix/
            "debian:docker://node:20-bullseye"
          ];
        };
      };
    };

    # Enable Podman for running...uh, runners.
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    systemd.services = {
      nginx.wants = [ config.systemd.services.forgejo.name ];
    } // lib.optionalAttrs (!cfg.autostart) { forgejo.wantedBy = lib.mkForce [ ]; };
  };
}
