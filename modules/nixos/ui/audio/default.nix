# Enables audio support.
{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.ui.audio;
in
{
  options = {
    ${namespace}.ui.audio = {
      enable = lib.mkEnableOption "Enables audio.";
      enableLowLatency = lib.mkEnableOption "Enables low-latency audio (may cause crackling) per https://wiki.nixos.org/wiki/PipeWire#Low-latency_setup.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable sound with pipewire.
    security.rtkit.enable = true;
    hardware.pulseaudio = {
      enable = false;
      package = pkgs.pulseaudioFull; # Enable extra audio codecs
    };

    services.pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };

      # Reduce audio latency per https://wiki.nixos.org/wiki/PipeWire#Low-latency_setup
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

    ${namespace}.ui.flatpak.packages = lib.mkIf config.${namespace}.ui.flatpak.enable [
      "com.github.wwmm.easyeffects"
    ];
  };
}
