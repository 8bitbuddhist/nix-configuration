{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.apps.writing;

  compile-manuscript = pkgs.writeShellScriptBin "compile-manuscript" (
    builtins.readFile ../../../../bin/compile-manuscript.sh
  );
in
{
  options = {
    ${namespace}.apps.writing.enable = lib.mkEnableOption "Enables writing and editing tools";
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
