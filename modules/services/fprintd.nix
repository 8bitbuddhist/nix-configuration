{ pkgs, config, lib, ... }:
let
	cfg = config.host.services.fprintd;
in
with lib;
{
	options = {
		host.services.fprintd.enable = mkEnableOption (mdDoc "Enables fingerprint recognition");
	};

	config = mkIf cfg.enable {
		nixpkgs.config.allowUnfree = true;
		services.fprintd = {
			enable = true;
			tod = {
				enable = true;
				driver = pkgs.libfprint-2-tod1-elan;
			};
		};
	};
}