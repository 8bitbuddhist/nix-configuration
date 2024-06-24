{
  pkgs,
  config,
  lib,
  ...
}:

let
  cfg = config.aux.system.apps.tmux;
in
with lib;
{
  options = {
    aux.system.apps.tmux.enable = mkEnableOption (mdDoc "Enables tmux - terminal multiplexer");
  };

  config = mkIf cfg.enable {
    programs.tmux = {
      enable = true;
      newSession = true;
      clock24 = true;
      extraConfig = ''
        set -g terminal-overrides 'xterm*:smcup@:rmcup@'
      '';
    };
  };
}
