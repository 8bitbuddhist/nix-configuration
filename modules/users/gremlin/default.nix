{
  pkgs,
  lib,
  config,
  ...
}:

# Define 'gremlin' user
let
  cfg = config.host.users.gremlin;
in
with lib;
{
  options = {
    host.users.gremlin = {
      enable = mkEnableOption (mdDoc "Enables gremlin user account");

      services.syncthing = {
        enable = mkEnableOption (mdDoc "Enables Syncthing");
        enableTray = mkEnableOption (mdDoc "Enables the Syncthing Tray application");
        autostart = mkOption {
          default = true;
          type = types.bool;
          description = "Whether to auto-start Syncthing on boot";
        };
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      # Add Gremlin account	
      users.users.gremlin = {
        isNormalUser = true;
        description = "Gremlin";
        uid = 1001;
        hashedPassword = config.secrets.users.gremlin.hashedPassword;
        extraGroups = [
          "networkmanager"
          "input"
        ];

        # Allow systemd services to keep running even while gremlin is logged out
        linger = true;
      };

      # Install gremlin-specific flatpaks
      services.flatpak.packages = lib.mkIf config.services.flatpak.enable [
        "com.google.Chrome"
        "com.slack.Slack"
      ];

      home-manager.users.gremlin = {
        imports = [
          ../common/home-manager/gnome.nix
          ../common/home-manager/zsh.nix
        ];

        home = {
          # Basic setup
          username = "gremlin";
          homeDirectory = "/home/gremlin";

          # The state version is required and should stay at the version you originally installed.
          stateVersion = "24.05";

          # Set environment variables
          sessionVariables = {
            KUBECONFIG = "/home/gremlin/.kube/config";
          };

          # Install packages specific to Gremlin
          packages = [ pkgs.awscli2 ];
        };

        programs = {
          # Let home Manager install and manage itself.
          home-manager.enable = true;

          # Set up git
          git = {
            enable = true;
            userName = config.secrets.users.aires.firstName;
            userEmail = config.secrets.users.aires.email;
            extraConfig = {
              push.autoSetupRemote = "true";
            };
          };

          # Set up Zsh
          zsh = {
            # Install and source the p10k theme
            plugins = [
              {
                name = "powerlevel10k";
                src = pkgs.zsh-powerlevel10k;
                file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
              }
              {
                name = "powerlevel10k-config";
                src = ./p10k-config;
                file = "p10k.zsh";
              }
            ];
            shellAliases = {
              please = "sudo";
            };
          };
        };

        # SSH entries set in nix-secrets
      };
    })

    # Enable Syncthing
    (mkIf cfg.services.syncthing.enable {
      users.users.gremlin = {
        packages = [
          pkgs.syncthing
          (mkIf cfg.services.syncthing.enableTray pkgs.syncthingtray)
        ];
      };

      home-manager.users.gremlin = {
        # Syncthing options
        services.syncthing = {
          enable = true;
          extraOptions = [
            "--gui-address=0.0.0.0:8081"
            "--home=${config.users.users.gremlin.home}/.config/syncthing"
            "--no-default-folder"
          ];
        };

        # Override the default Syncthing settings so it doesn't start on boot
        systemd.user.services."syncthing" = mkIf (!cfg.services.syncthing.autostart) {
          Install = lib.mkForce { };
        };
      };
    })
  ];
}
