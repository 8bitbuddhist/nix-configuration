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
			#hugo # Temporarily disabled until this build issue gets fixed: https://github.com/NixOS/nixpkgs/pull/298026
			rsync
			yarn
		];
	};
}