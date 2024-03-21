{ pkgs, config, lib, inputs, ... }:

# System options
let
	cfg = config.host.system;
in
with lib;
{
	config = {
		# Set up the environment
		environment = {
			# Install base packages
			systemPackages = with pkgs; [
				bash
				dconf	# Needed to fix an issue with Home-manager. See https://github.com/nix-community/home-manager/issues/3113
				git
				home-manager
				nano
				p7zip
				fastfetch
			];

			# Set default editor to nano
			variables.EDITOR = "nano";
		
			# System configuration file overrides
			etc = {
				# Reduce systemd logout time to 30s
				"systemd/system.conf.d/10-reduce-logout-wait-time.conf" = {
					text = ''
						[Manager]
						DefaultTimeoutStopSec=30s
					'';
				};
			};
		};

		# Configure automatic updates
		system = {
			# Enable automatic updates
			autoUpgrade = {
				enable = true;
				flake = "${config.users.users.aires.home}/Development/nix-configuration";
				flags = [
					"--update-input"
					"nixpkgs"
					"--commit-lock-file" # Create a new commit when flake.lock updates
				];
				dates = "daily";
				allowReboot = false;
			};
		};

		# Set your time zone.
		time.timeZone = "America/New_York";

		# Select internationalisation properties.
		i18n = {
			defaultLocale = "en_US.UTF-8";

			extraLocaleSettings = {
				LC_ADDRESS = "en_US.UTF-8";
				LC_IDENTIFICATION = "en_US.UTF-8";
				LC_MEASUREMENT = "en_US.UTF-8";
				LC_MONETARY = "en_US.UTF-8";
				LC_NAME = "en_US.UTF-8";
				LC_NUMERIC = "en_US.UTF-8";
				LC_PAPER = "en_US.UTF-8";
				LC_TELEPHONE = "en_US.UTF-8";
				LC_TIME = "en_US.UTF-8";
			};
		};

		# Configure nix
		nix = {
			# Enables Flakes
			settings.experimental-features = [ "nix-command" "flakes" ];

			# Enable periodic nix store optimization
			optimise.automatic = true;

			# Enable garbage collection
			gc = {
				automatic = true;
				dates = "daily";
				options = "--delete-older-than 30d";
			};

			# Configure NixOS to use the same software channel as Flakes
			registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
			nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;
		};

		# Set up base apps
		programs = {
			direnv.enable = true;

			nano = {
				enable = true;
				syntaxHighlight = true;
				nanorc = ''
					set linenumbers
					set tabsize 4
					set softwrap
				'';
			};
		};

    services = {
      # Scrub BTRFS partitions if the root partition is btrfs
      btrfs.autoScrub = lib.mkIf (config.fileSystems."/".fsType == "btrfs") {
        enable = true;
        interval = "weekly";
        fileSystems = [ "/" ];
      };

      # Enable fwupd (firmware updater)
      fwupd.enable = true;

      # Allow systemd user services to keep running after the user has logged out
      logind.killUserProcesses = false;
    };
	};
}
