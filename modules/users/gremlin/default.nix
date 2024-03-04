{ pkgs, lib, config, ... }:

# Define 'gremlin' user
let
	cfg = config.host.users.gremlin;
in
with lib;
{
	options = {
		host.users.gremlin = {
			enable = mkEnableOption (mdDoc "Enables gremlin user account");
			
			services.syncthing = {
				enable = mkEnableOption (mdDoc "Enables Syncthing");
				enableTray = mkEnableOption (mdDoc "Enables the Syncthing Tray application");
				autostart = mkOption {
					default = true;
					type = types.bool;
					description = "Whether to auto-start Syncthing on boot";
				};
			};
		};
	};

	config = mkMerge [
		(mkIf cfg.enable {
			# Add Gremlin account	
			users.users.gremlin = {
				isNormalUser = true;
				description = "Gremlin";
				uid = 1001;
				extraGroups = [ "networkmanager" "input" ];

				# Allow systemd services to keep running even while gremlin is logged out
				linger = true;
			};

			# Install gremlin-specific flatpaks
			services.flatpak.packages = lib.mkIf config.services.flatpak.enable [
				"com.google.Chrome"
				"com.slack.Slack"
			];

			home-manager.users.gremlin = {
				imports = [
					../common/gnome.nix
				];
				
				# The state version is required and should stay at the version you originally installed.
				home.stateVersion = "24.05";

				# Let home Manager install and manage itself.
				programs.home-manager.enable = true;

				# Basic setup
				home.username = "gremlin";
				home.homeDirectory = "/home/gremlin";

				# Set up git
				programs.git = {
					# Name and email set in nix-secrets
					enable = true;
					extraConfig = {
						push.autoSetupRemote = "true";
					};
				};

				# SSH entries set in nix-secrets

				# Set up Zsh
				programs.zsh = {
					enable = true;
					# Install and source the p10k theme
					plugins = [
						{ name = "powerlevel10k"; src = pkgs.zsh-powerlevel10k; file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme"; }
						{ name = "powerlevel10k-config"; src = ./p10k-config; file = "p10k.zsh"; }
					];
					enableAutosuggestions = true;
					syntaxHighlighting.enable = true;
					history.ignoreDups = true;	# Do not enter command lines into the history list if they are duplicates of the previous event.
					prezto = {
						git.submoduleIgnore = "untracked";	# Ignore submodules when they are untracked.
					};
					shellAliases = {
						please = "sudo";
					};

					oh-my-zsh = {
						enable = true;
						plugins = [
							"git"
						];
					};
				};
			};
		})

		# Enable Syncthing
		(mkIf cfg.services.syncthing.enable {
			users.users.gremlin = {
				packages = [
					pkgs.syncthing
					(mkIf cfg.services.syncthing.enableTray pkgs.syncthingtray)
				];
			};

			home-manager.users.gremlin = {
				# Syncthing options
				services.syncthing = {
					enable = true;
					extraOptions = [
						"--gui-address=0.0.0.0:8081"
						"--home=${config.users.users.gremlin.home}.config/syncthing"
						"--no-default-folder"
					];		
				};

				# Override the default Syncthing settings so it doesn't start on boot
				systemd.user.services."syncthing" = mkIf (!cfg.services.syncthing.autostart) {
					Install = lib.mkForce {};
				};
			};
		})
	];
}
