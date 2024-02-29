{ pkgs, config, lib, ... }:

let
	cfg = config.host.apps.hugo;
in
with lib;
{
	options = {
		host.apps.hugo.enable = mkEnableOption (mdDoc "Enables Hugo and webdev tools");
	};

	config = mkIf cfg.enable {
		environment.systemPackages = with pkgs; [
			hugo
			rsync
			yarn
		];
	};
}