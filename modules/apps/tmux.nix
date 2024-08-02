{ config, lib, ... }:

let
  cfg = config.aux.system.apps.tmux;
in
{
  options = {
    aux.system.apps.tmux.enable = lib.mkEnableOption "Enables tmux - terminal multiplexer";
  };

  config = lib.mkIf cfg.enable {
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
