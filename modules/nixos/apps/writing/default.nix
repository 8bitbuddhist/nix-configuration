{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.aux.system.apps.writing;

  compile-manuscript = pkgs.writeShellScriptBin "compile-manuscript" (
    builtins.readFile ../../../../bin/compile-manuscript.sh
  );
in
{
  options = {
    aux.system.apps.writing.enable = lib.mkEnableOption "Enables writing and editing tools";
  };

  config = lib.mkIf cfg.enable {
    # Install packages for building ebooks
    environment.systemPackages = with pkgs; [
      haskellPackages.pandoc
      haskellPackages.pandoc-cli
      haskellPackages.pandoc-crossref
      (texlive.combine { inherit (texlive) scheme-small draftwatermark; })
      compile-manuscript
    ];
  };
}
