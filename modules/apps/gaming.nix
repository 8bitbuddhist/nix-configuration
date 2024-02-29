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
		services.flatpak.packages = lib.mkIf (config.services.flatpak.enable == true) [
			"gg.minion.Minion"
			"com.valvesoftware.Steam"
			"org.firestormviewer.FirestormViewer"
		];
	};
}
