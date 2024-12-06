# Configure formatter for .nix and other repo files
{ pkgs, ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    beautysh.enable = true;
    nixfmt = {
      enable = true;
      package = pkgs.nixfmt-rfc-style;
    };
    prettier.enable = true;
    yamlfmt.enable = true;
  };
}