{ pkgs, lib, config, ... }:

let
	cfg = config.host.ui.audio;
in
with lib;
{
	options = {
		host.ui.audio.enable = mkEnableOption (mdDoc "Enables audio");
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
	};
}