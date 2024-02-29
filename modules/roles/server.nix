{ config, lib, modulesPath, pkgs, ... }:
let
	role = config.host.role;
in
	with lib;
{
	imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

	config = mkIf (role == "server") {
		environment.systemPackages = with pkgs; [
			direnv
			htop
		];
	};
}