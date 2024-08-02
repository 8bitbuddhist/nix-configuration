{
  pkgs,
  lib,
  config,
  ...
}:

# Define 'aires'
let
  cfg = config.aux.system.users.aires;
in
{
  options = {
    aux.system.users.aires = {
      enable = lib.mkEnableOption "Enables aires user account";
      autologin = lib.mkEnableOption "Automatically logs aires in on boot";

      services.syncthing = {
        enable = lib.mkEnableOption "Enables Syncthing";
        enableTray = lib.mkEnableOption "Enables the Syncthing Tray application";
        autostart = lib.mkOption {
          default = true;
          type = lib.types.bool;
          description = "Whether to auto-start Syncthing on boot";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        users.users.aires = {
          isNormalUser = true;
          description = "Aires";
          uid = 1000;
          hashedPassword = config.secrets.users.aires.hashedPassword;
          extraGroups = [
            "input"
            "networkmanager"
            "plugdev"
            "tss"
            "wheel"
          ]; # tss group has access to TPM devices

          # Allow systemd services to run even while aires is logged out
          linger = true;
        };

        # Configure home-manager
        home-manager.users.aires = {
          imports = [
            ../common/home-manager/gnome.nix
            ../common/home-manager/zsh.nix
          ];

          home = {
            # The state version is required and should stay at the version you originally installed.
            stateVersion = "24.05";

            # Basic setup
            username = "aires";
            homeDirectory = "/home/aires";

            # Install extra packages, specifically gnome extensions
            packages = lib.mkIf config.aux.system.ui.desktops.gnome.enable [
              pkgs.gnomeExtensions.wallpaper-slideshow
            ];

            # Set environment variables
            sessionVariables = {
              KUBECONFIG = "/home/aires/.kube/config";
            };

            # Create .face file
            file.".face".source = ./face.png;
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
                aliases.pull = "!git pull && git submodule foreach --recursive 'git pull origin main'";
              };
            };

            # Set up SSH
            ssh = {
              enable = true;
              matchBlocks = config.secrets.users.aires.sshConfig;
            };

            # Set up Zsh
            zsh = {
              oh-my-zsh = {
                theme = "gentoo";
              };
              shellAliases = {
                update = "upgrade";
                upgrade = "nh os boot --update --ask";
              };
              loginExtra = "fastfetch";
            };
          };

          # Gnome settings specific to aires on Shura
          /*
            dconf.settings = lib.mkIf (config.networking.hostName == "Shura") {
              "org/gnome/desktop/interface" = {
                # Increase font scaling;
                text-scaling-factor = 1.3;

                # Dark mode
                color-scheme = "prefer-dark";
              };
            };
          */
        };
      }

      # Autologin aires
      (lib.mkIf cfg.autologin {
        services.displayManager.autoLogin = {
          enable = true;
          user = "aires";
        };
        systemd.services = {
          "getty@tty1".enable = false;
          "autovt@tty1".enable = false;
        };
      })

      # Enable Syncthing
      (lib.mkIf cfg.services.syncthing.enable {
        users.users.aires.packages = [
          pkgs.syncthing
          (lib.mkIf cfg.services.syncthing.enableTray pkgs.syncthingtray)
        ];

        # Open port 8080
        networking.firewall.allowedTCPPorts = [ 8080 ];

        home-manager.users.aires = {
          # Syncthing options
          services.syncthing = {
            enable = true;
            extraOptions = [
              "--gui-address=0.0.0.0:8080"
              "--home=${config.users.users.aires.home}/.config/syncthing"
              "--no-default-folder"
            ];
          };

          # Override the default Syncthing settings so it doesn't start on boot
          systemd.user.services."syncthing" = lib.mkIf (!cfg.services.syncthing.autostart) {
            wantedBy = lib.mkForce { };
          };
        };
      })
    ]
  );
}
