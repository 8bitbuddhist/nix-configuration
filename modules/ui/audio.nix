# Enables audio support.
{
  pkgs,
  lib,
  config,
  ...
}:

let
  cfg = config.aux.system.ui.audio;
in
{
  options = {
    aux.system.ui.audio = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables audio.");
      enableLowLatency = lib.mkEnableOption (
        lib.mdDoc "Enables low-latency audio (may cause crackling) per https://nixos.wiki/wiki/PipeWire#Low-latency_setup."
      );
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable sound with pipewire.
    sound.enable = true;
    security.rtkit.enable = true;
    hardware.pulseaudio = {
      enable = false;
      package = pkgs.pulseaudioFull; # Enable extra audio codecs
    };

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      # Reduce audio latency per https://nixos.wiki/wiki/PipeWire#Low-latency_setup
      extraConfig.pipewire = lib.mkIf cfg.enableLowLatency {
        "92-low-latency.conf" = {
          "context.properties" = {
            "default.clock.rate" = 48000;
            "default.clock.quantum" = 32;
            "default.clock.min-quantum" = 32;
            "default.clock.max-quantum" = 32;
          };
        };
      };
    };
  };
}
