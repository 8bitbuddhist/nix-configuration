{ pkgs, home-manager, lib, config, ... }:

# Settings specific to Haven

let
	start-haven = pkgs.writeText "info" (builtins.readFile ./start-haven.sh);
in
{
	imports = [
		./hardware-configuration.nix
		../common
	];

	system.stateVersion = "24.05";

	host = {
		role = "server";
		services = {
			apcupsd.enable = true;
			duplicacy-web = {
				enable = true;
				autostart = false;
				environment = "${config.users.users.aires.home}";
			};
			k3s = {
				enable = true;
				role = "server";
			};
			msmtp.enable = true;
		};
		users = {
			aires = {
				enable = true;
				services = {
					syncthing = {
						enable = true;
						autostart = false;
					};
				};
			};
			media.enable = true;
		};
	};

	# Enable SSH
	services.openssh = {
		enable = true;
		ports = [ 33105 ];

		settings = {
			# require public key authentication for better security
			PasswordAuthentication = false;
			KbdInteractiveAuthentication = false;
			PubkeyAuthentication = true;
			
			PermitRootLogin = "without-password";
		};
	};

	# Add script for booting Haven
	systemd.tmpfiles.rules = [
		"d ${config.users.users.aires.home}/bin/ 0700 aires users"	# First, make sure the directory exists
		"L+ ${config.users.users.aires.home}/bin/start-haven 0700 - - - ${start-haven}"
	];

}