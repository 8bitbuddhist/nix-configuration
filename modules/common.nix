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
          dates = "daily";
          extraArgs = "--keep-since 7d --keep 10"; # Keep the last 10 entries
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
  };
}
