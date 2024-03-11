{ config, lib, pkgs, ... }:

# Gaming-related settings
let
	cfg = config.host.apps.gaming;
in
with lib;
{
	options = {
		host.apps.gaming.enable = mkEnableOption (mdDoc "Enables gaming features");
	};

	config = mkIf cfg.enable {
		services.flatpak.packages = lib.mkIf config.services.flatpak.enable [
			"gg.minion.Minion"
			"com.valvesoftware.Steam"
			"org.firestormviewer.FirestormViewer"
		];

		# Enable Xbox controller driver (XPadNeo)
		boot = {
			extraModulePackages = with config.boot.kernelPackages; [ xpadneo ];
			kernelModules = [ "hid_xpadneo" ];
		};
	};
}
