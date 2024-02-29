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

		# Enable Pipewire codec support - see https://pipewire.pages.freedesktop.org/wireplumber/daemon/configuration/bluetooth.html
		# FIXME: Editing etc packages causes a "permission denied" build error. Not sure of the cause.
		/*
		environment.etc = lib.mkIf (config.sound.enable == true) {
			"wireplumber/bluetooth.lua.d/51-bluez-config.lua".text = ''
				bluez_monitor.properties = {
					["bluez5.enable-sbc-xq"] = true,
					["bluez5.enable-msbc"] = true,
					["bluez5.enable-hw-volume"] = true,
					["bluez5.headset-roles"] = "[ hsp_hs hsp_ag hfp_hf hfp_ag ]",
					["bluez5.auto-connect"] = "[ hfp_hf hsp_hs a2dp_sink ]"
				}
			'';

			# Reduce audio latency per https://nixos.wiki/wiki/PipeWire#Low-latency_setup
			"pipewire/pipewire.conf.d/92-low-latency.conf".text = ''
				context.properties = {
					default.clock.rate = 48000
					default.clock.quantum = 32
					default.clock.min-quantum = 32
					default.clock.max-quantum = 32
				}
			'';
		};
		*/
	};
}