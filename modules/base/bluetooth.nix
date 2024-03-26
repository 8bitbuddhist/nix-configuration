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
	};
}