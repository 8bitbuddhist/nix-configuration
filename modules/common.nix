# Modules common to all systems
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

{
  config = {
    # Install base packages
    aux.system.packages = with pkgs; [
      fastfetch # Show a neat system statistics screen when opening a terminal
      git-crypt # Secrets management
      htop # System monitor
      zellij # Terminal multiplexer
    ];

    # Install the nos helper script
    aux.system.nixos-operations-script.enable = true;

    nixpkgs.overlays = [
      (final: _prev: {
        # Allow packages from the unstable repo by using 'pkgs.unstable'
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };

        # Define custom functions using 'pkgs.util'
        util = {
          # Parses the domain from a URL
          getDomainFromURL =
            url:
            let
              parsedURL = (lib.strings.splitString "." url);
            in
            builtins.concatStringsSep "." [
              (builtins.elemAt parsedURL 1)
              (builtins.elemAt parsedURL 2)
            ];
        };
      })
    ];

    programs = {
      # Install ZSH for all users
      zsh.enable = true;

      # Enable NH, an alternative nixos-rebuild frontend.
      # https://github.com/viperML/nh
      nh = {
        enable = true;
        flake = "${config.secrets.nixConfigFolder}";
      };
      # Configure nano
      nano.nanorc = ''
        set tabsize 4
        set softwrap
        set autoindent
        set indicator
      '';
    };

    # Set ZSH as the default shell
    users.defaultUserShell = pkgs.zsh;
  };
}
