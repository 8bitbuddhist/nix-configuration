# Modules common to all systems
{
  pkgs,
  config,
  inputs,
  ...
}:

{
  config = {
    # Install ZSH for all users
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;

    aux.system = {
      packages = with pkgs; [
        fastfetch # Show a neat system statistics screen when opening a terminal
        nh # Nix Helper: https://github.com/viperML/nh
        zellij # Terminal multiplexer
      ];
    };

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
      # Enable NH, an alternative nixos-rebuild frontend.
      nh = {
        enable = true;
        flake = "${config.secrets.nixConfigFolder}";
      };
      # Do some additional Nano configuration
      nano.nanorc = ''
        set linenumbers
        set tabsize 4
        set softwrap
        set autoindent
        set indicator
      '';
    };

    services.fail2ban.enable = true;
  };
}
