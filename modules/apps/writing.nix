{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.host.apps.writing;
in
with lib;
{
  options = {
    host.apps.writing.enable = mkEnableOption (mdDoc "Enables writing and editing tools");
  };

  config = mkIf cfg.enable {
    # Install packages for building ebooks
    environment.systemPackages = with pkgs; [
      haskellPackages.pandoc
      haskellPackages.pandoc-cli
      haskellPackages.pandoc-crossref
      texliveSmall
    ];

    # Spelling and grammer checking: hosted on localhost:8081
    services.languagetool = {
      enable = true;
      port = 8090;
      public = false;
      allowOrigin = "*";
    };
  };
}
