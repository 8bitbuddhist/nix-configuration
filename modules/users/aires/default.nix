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
        home = lib.mkOption {
          default = "${config.users.users.aires.home}/.config/syncthing";
          type = lib.types.str;
          description = "Where to store Syncthing's configuration files";
        };
        web = {
          enable = lib.mkEnableOption "Enables the Syncthing web UI.";
          port = lib.mkOption {
            type = lib.types.int;
            default = 8384;
            description = "The port to host Syncthing web on.";
          };
          public = lib.mkEnableOption "Whether to expose the Syncthing web UI to the network.";
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
            "users"
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
                core.editor = config.aux.system.editor;
                merge.conflictStyle = "zdiff3";
                pull.ff = "only";
                push.autoSetupRemote = "true";
                safe.directory = "${config.secrets.nixConfigFolder}/.git";
                submodule.recurse = true;
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
                nos = "nixos-operations-script";
                z = "zellij";
                update = "upgrade";
                upgrade = "nos --update";
              };
              loginExtra = "fastfetch --memory-percent-green 75 --memory-percent-yellow 90";
            };
          };
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

      # Configure Syncthing
      (lib.mkIf cfg.services.syncthing.enable {
        users.users.aires.packages = [ pkgs.syncthing ];

        services.flatpak.packages = lib.mkIf (
          config.aux.system.ui.flatpak.enable && cfg.services.syncthing.enableTray
        ) [ "io.github.martchus.syncthingtray" ];

        # If the web UI is public, open the port in the firewall
        networking.firewall.allowedTCPPorts =
          with cfg.services.syncthing.web;
          lib.mkIf (enable && public) [ port ];

        home-manager.users.aires = {
          services.syncthing = {
            enable = true;
            extraOptions =
              let
                listenAddress =
                  with cfg.services.syncthing.web;
                  (if (enable && public) then "0.0.0.0" else "127.0.0.1");
              in
              [
                "--gui-address=${listenAddress}:${builtins.toString cfg.services.syncthing.web.port}"
                "--home=${cfg.services.syncthing.home}"
                "--no-default-folder"
              ];
          };

          systemd.user.services."syncthing".Unit.RequiresMountsFor = cfg.services.syncthing.home;
        };
      })
    ]
  );
}
