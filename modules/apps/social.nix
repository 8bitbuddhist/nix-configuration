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
			# Install Beeper, but override the InstallPhase so it uses Wayland.
			# Check Flatpak status here: https://github.com/daegalus/beeper-flatpak-wip/issues/1
			(beeper.overrideAttrs (oldAttrs: {
				installPhase = ''
					wrapProgram $out/bin/beeper \
					--add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=wayland --enable-features=WaylandWindowDecorations}} --no-update"
				'';
			}))
		];

		host.ui.flatpak.enable = true;
		services.flatpak.packages = [
			"com.discordapp.Discord"
		];
	};
}
