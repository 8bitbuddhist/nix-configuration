# Configure Git to support git-crypt
{ pkgs, ... }:
{
  programs.git = {
    extraConfig = {
      filter."git-crypt" = {
        required = true;
        smudge = "/run/current-system/sw/bin/git-crypt smudge";
        clean = "/run/current-system/sw/bin/git-crypt clean";
      };
      diff."git-crypt" = {
        textconv = "/run/current-system/sw/bin/git-crypt diff";
      };
    };
  };
}
