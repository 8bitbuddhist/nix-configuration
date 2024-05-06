{ pkgs, config, lib, ... }:

let
	cfg = config.host.apps.social;
in
with lib;
{
	options = {
		host.apps.social.enable = mkEnableOption (mdDoc "Enables chat apps");
	};

	config = mkIf cfg.enable {
		nixpkgs.config.allowUnfree = true;
		environment.systemPackages = with pkgs; [
			# Check Beeper Flatpak status here: https://github.com/daegalus/beeper-flatpak-wip/issues/1
			beeper
		];

		host.ui.flatpak.enable = true;
		services.flatpak.packages = [
			"com.discordapp.Discord"
		];
	};
}
