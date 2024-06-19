{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.host.apps.writing;
in
{
  options = {
    host.apps.writing = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables writing and editing tools");
      ngrams.enable = lib.mkEnableOption (
        lib.mdDoc "Enables ngrams for improved grammar detection (warning: results in an 8GB+ download)."
      );
    };
  };

  config = lib.mkIf cfg.enable {
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
      # Enable Ngrams
      settings.languageModel = lib.mkIf cfg.ngrams.enable "${
        (pkgs.callPackage ../../packages/languagetool-ngrams.nix { inherit pkgs lib; })
      }/ngrams";
    };
  };
}
