{
  lib,
  config,
  namespace,
  ...
}:

# Define 'aires'
let
  cfg = config.${namespace}.users.aires;
in
{
  options = {
    ${namespace}.users.aires = {
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
          hashedPassword = config.${namespace}.secrets.users.aires.hashedPassword;
          extraGroups = [
            "input"
            "networkmanager"
            "plugdev"
            "tss" # For access to TPM devices
            "wheel"
            "users"
            (lib.mkIf config.programs.adb.enable "adbusers")
          ];

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
              userName = config.${namespace}.secrets.users.aires.firstName;
              userEmail = config.${namespace}.secrets.users.aires.email;
              extraConfig = {
                core.editor = config.${namespace}.editor;
                merge.conflictStyle = "zdiff3";
                pull.ff = "only";
                push.autoSetupRemote = "true";
                safe.directory = "${config.${namespace}.secrets.nixConfigFolder}/.git";
                submodule.recurse = true;
                credential.helper = "/run/current-system/sw/bin/git-credential-libsecret";
              };
            };

            # Set up SSH
            ssh = {
              enable = true;
              matchBlocks = config.${namespace}.secrets.users.aires.sshConfig;
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
