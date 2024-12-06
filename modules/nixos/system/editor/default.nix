# Basic system-wide text editor configuration.
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.editor;
in
{
  options = {
    ${namespace}.editor = lib.mkOption {
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
