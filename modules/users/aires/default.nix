{
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
                credential.helper = "/run/current-system/sw/bin/git-credential-libsecret";
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
                com = "compile-manuscript";
                nos = "nixos-operations-script";
                z = "zellij";
                update = "upgrade";
                upgrade = "nos --update";
              };
              loginExtra = ''
                fastfetch --memory-percent-green 75 --memory-percent-yellow 90
              '';
            };
          };

          # Run the SSH agent on login
          systemd.user.services."ssh-agent" = {
            Unit.Description = "Manually starts the SSH agent.";
            Service.ExecStart = ''
              eval "$(ssh-agent -s)"
            '';
            Install.WantedBy = [ "multi-user.target" ]; # starts after login
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
    ]
  );
}
