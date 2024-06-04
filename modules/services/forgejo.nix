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
      domain = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The root domain that Forgejo will be hosted on.";
        example = "example.com";
      };
      home = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "Where to store Forgejo's files";
        example = "/home/forgejo";
      };
      url = lib.mkOption {
        default = "";
        type = lib.types.str;
        description = "The complete URL where Forgejo is hosted.";
        example = "https://forgejo.example.com";
      };
      actions = {
        enable = lib.mkEnableOption (lib.mdDoc "Enables a local Forgejo Actions runner.");
        token = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "Token used to authenticate the runner with Forgejo.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      forgejo-cli
      pkgs.podman-tui
    ];
    services = {
      forgejo = {
        enable = true;
        lfs.enable = true;
        settings.server = {
          DOMAIN = cfg.domain;
          ROOT_URL = cfg.url;
          HTTP_PORT = 3000;
        };
        useWizard = true;
      } // lib.optionalAttrs (cfg.home != null) { stateDir = cfg.home; };

      # Enable runner for CI actions
      gitea-actions-runner = lib.mkIf cfg.actions.enable {
        package = pkgs.forgejo-actions-runner;
        instances.default = {
          enable = true;
          name = config.networking.hostName;
          url = cfg.url;
          token = cfg.actions.token;
          labels = [
            "nix:docker://nixos/nix" # Shoutout to Icewind 1991 for this syntax: https://icewind.nl/entry/gitea-actions-nix/
            "debian:docker://node:20-bullseye"
            "ubuntu-latest:docker://ubuntu:latest"
          ];
          settings = {
            # For an example of configuring in Nix: https://git.clan.lol/clan/clan-infra/src/branch/main/modules/web01/gitea/actions-runner.nix
            # For an example of the different options available: https://gitea.com/gitea/act_runner/src/branch/main/internal/pkg/config/config.example.yaml
            container.options = "-v /nix:/nix";
            container.validVolumes = [ "/nix" ];
          };
        };
      };
    };

    systemd.services = {
      nginx.wants = [ config.systemd.services.forgejo.name ];
    } // lib.optionalAttrs (!cfg.autostart) { forgejo.wantedBy = lib.mkForce [ ]; };

    # Enable Podman for running...uh, runners.
    virtualisation = lib.mkIf cfg.actions.enable {
      containers.enable = true;
      podman = {
        enable = true;

        # Create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;

        # Required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    # Allow containers to make DNS queries (https://www.reddit.com/r/NixOS/comments/199f16j/why_dont_my_podman_containers_have_internet_access/)
    networking.firewall.interfaces.podman4 = lib.mkIf cfg.actions.enable {
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };
}
