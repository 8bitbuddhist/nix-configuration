# See https://nixos.wiki/wiki/Msmtp
{ config, lib, ... }:

let
	cfg = config.host.services.msmtp;
in
with lib;
{
	options = {
		host.services.msmtp.enable = mkEnableOption (mdDoc "Enables mail server");
	};

	config = mkIf cfg.enable {
		programs.msmtp = {
			enable = true;
			# Authentication details set in nix-secrets
		};
	};
}