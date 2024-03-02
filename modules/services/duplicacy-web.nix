{ pkgs, config, lib, ... }:

let
	cfg = config.host.services.duplicacy-web;
	duplicacy-web = pkgs.callPackage ../packages/duplicacy-web.nix { inherit pkgs lib; };
in
with lib;
rec {
	options = {
		host.services.duplicacy-web = {
			enable = mkEnableOption (mdDoc "Enables duplicacy-web");
			autostart = mkOption {
				default = true;
				type = types.bool;
				description = "Whether to auto-start duplicacy-web on boot";
			};

			environment = mkOption {
				default = "";
				type = types.str;
				description = "Environment where duplicacy-web stores its config files";
			};
		};
	};

	config = mkIf cfg.enable {
		nixpkgs.config.allowUnfree = true;
		environment.systemPackages = [
			duplicacy-web
		];

		networking.firewall.allowedTCPPorts = [ 3875 ];

		# Install systemd service.
		systemd.services."duplicacy-web" = {
			enable = true;
			wants = [ "network-online.target" ];
			after = [ "syslog.target" "network-online.target" ];
			description = "Start the Duplicacy backup service and web UI";
			serviceConfig = {
				Type = "simple";
				ExecStart = ''${duplicacy-web}/duplicacy-web''; 
				Restart = "on-failure";
				RestartSrc = 10;
				KillMode = "process";
			};
			environment = {
				HOME = cfg.environment;
			};
		}	//	optionalAttrs cfg.autostart { wantedBy = ["multi-user.target"]; };	# Start at boot if autostart is enabled.
	};
}
