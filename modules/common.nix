# Modules common to all systems
{ pkgs, config, ... }:

{
  config = {
    # Install ZSH for all users
    programs.zsh.enable = true;
    users.defaultUserShell = pkgs.zsh;

    aux.system = {
      packages = with pkgs; [
        fastfetch # Show a neat system statistics screen when opening a terminal
        nh # Nix Helper: https://github.com/viperML/nh
      ];
    };

    programs = {
      # Enable NH, an alternative nixos-rebuild frontend.
      nh = {
        enable = true;
        flake = "${config.secrets.nixConfigFolder}";

        # Alternative garbage collection system to nix.gc.automatic
        clean = {
          enable = true;
          dates = "weekly"; # Runs at 12:00 AM on Mondays
          extraArgs = "--keep-since 14d --keep 10"; # By default, keep the last 10 entries (or two weeks) of generations
        };
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
