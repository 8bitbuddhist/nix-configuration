{ config, lib, modulesPath, pkgs, ... }:
let
	inherit (config.host) role;
in
	with lib;
{
	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	config = mkIf (role == "server") {
		host.apps.tmux.enable = true;
		environment.systemPackages = with pkgs; [
			htop
			mdadm
		];
	};
}
