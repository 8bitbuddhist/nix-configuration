{ pkgs, lib, config, ... }:

let
	cfg = config.host.ui.audio;
in
with lib;
{
	options = {
		host.ui.audio = {
			enable = mkEnableOption (mdDoc "Enables audio");
			enableLowLatency = mkEnableOption (mdDoc "Enables low-latency audio (may cause crackling) per https://nixos.wiki/wiki/PipeWire#Low-latency_setup ");
		};
	};

	config = mkIf cfg.enable {
		# Enable sound with pipewire.
		sound.enable = true;
		security.rtkit.enable = true;
		hardware.pulseaudio = {
			enable = false;
			package = pkgs.pulseaudioFull;	# Enable extra audio codecs
		};

		services.pipewire = {
			enable = true;
			alsa.enable = true;
			alsa.support32Bit = true;
			pulse.enable = true;
			jack.enable = true;
		};

		services.flatpak.packages =	mkIf config.host.ui.flatpak.enable [
			"com.github.wwmm.easyeffects"	
		];

	    # Reduce audio latency per https://nixos.wiki/wiki/PipeWire#Low-latency_setup
		services.pipewire.extraConfig.pipewire = mkIf cfg.enableLowLatency {
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
}
