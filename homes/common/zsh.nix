# Additional ZSH settings via Home Manager
{ pkgs, ... }:
{
  programs = {
    command-not-found.enable = true;

    zsh = {
      enable = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.ignoreDups = true; # Do not enter command lines into the history list if they are duplicates of the previous event.
      prezto = {
        git.submoduleIgnore = "untracked"; # Ignore submodules when they are untracked.
      };
      plugins = [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.8.0";
            sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
          };
        }
      ];
      sessionVariables = {
        NIX_AUTO_RUN = true;
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "command-not-found"
          "cp"
          "direnv"
          "dotenv"
          "extract"
          "git"
          "systemd"
        ];
      };
    };
  };
}
