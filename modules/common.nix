# Modules common to all systems
{
  pkgs,
  config,
  inputs,
  ...
}:

{
  config = {
    # Install base packages
    aux.system.packages = with pkgs; [
      fastfetch # Show a neat system statistics screen when opening a terminal
      htop # System monitor
      zellij # Terminal multiplexer
    ];

    # Allow packages from the unstable repo by using 'pkgs.unstable'
    nixpkgs.overlays = [
      (final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
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
