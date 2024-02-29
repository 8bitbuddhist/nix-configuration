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
			accounts.default = {
				auth = true;
				tls = true;
				from = "root@${config.networking.hostName}";
				user = "root";
				# SMTP host and password set in nix-secrets
			};
		};
	};
}