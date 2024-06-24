# Basic system-wide text editor configuration.
{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.aux.system.editor;
in
{
  options = {
    aux.system.editor = lib.mkOption {
      description = "Selects the default text editor.";
      default = "nano";
      type = lib.types.enum [
        "vim"
        "nano"
        "emacs"
      ];
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg == "emacs") {
      services.emacs = {
        enable = true;
        defaultEditor = true;
      };
    })
    (lib.mkIf (cfg == "nano") {
      programs.nano = {
        enable = true;
        syntaxHighlight = true;
      };
      environment.variables."EDITOR" = "nano";
    })
    (lib.mkIf (cfg == "vim") { programs.vim.defaultEditor = true; })
  ];
}
