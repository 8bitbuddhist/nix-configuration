{ config, lib, ... }:

let 
	cfg = config.host.apps.office;
in
with lib;
{
	options = {
		host.apps.office.enable = mkEnableOption (mdDoc "Enables office and workstation apps");
	};

	config = mkIf cfg.enable {
		host.ui.flatpak.enable = true;

		services.flatpak.packages = [
			"org.libreoffice.LibreOffice"
			"us.zoom.Zoom"
		];

		# Spelling and grammer checking: hosted on localhost:8081
		services.languagetool = {
			enable = true;
			public = false;
			allowOrigin = "*";
		};
	};
}