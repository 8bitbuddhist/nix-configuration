{ lib, config, pkgs, ... }:

let
	cfg = config.host.ui.bluetooth;
in
with lib;
{

	options = {
		host.ui.bluetooth = {
			enable = mkEnableOption (mdDoc "Enables bluetooth");
		};
	};

	config = mkIf cfg.enable {
		# Set up Bluetooth
		hardware.bluetooth = {
			enable = true;
			powerOnBoot = true;
			settings = {
				General = {
					Enable = "Source,Sink,Media,Socket";
					Experimental = true;
					KernelExperimental = true;
				};
			};
		};

		# Add Bluetooth LE audio support
		environment.systemPackages = with pkgs; [
			liblc3
		];

		# Reduce audio latency per https://nixos.wiki/wiki/PipeWire#Low-latency_setup
		services.pipewire.extraConfig.pipewire = lib.mkIf (config.sound.enable == true) {
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