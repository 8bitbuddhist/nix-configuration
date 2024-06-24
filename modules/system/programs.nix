# Set up program defaults
{ config, ... }:
{
  # Set up base apps
  programs = {
    direnv.enable = true;

    nano = {
      enable = true;
      syntaxHighlight = true;
      nanorc = ''
        set linenumbers
        set tabsize 4
        set softwrap
        set autoindent
        set indicator
      '';
    };

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

    # Support for standard, dynamically-linked executables
    nix-ld.enable = true;
  };
}
