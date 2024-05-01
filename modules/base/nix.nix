# Nix configuration
{ pkgs, config, lib, inputs, ... }: {
	nix = {
		# Use the latest and greatest Nix
		package = pkgs.nixVersions.unstable;

		settings = {
			# Enables Flakes
			experimental-features = [ "nix-command" "flakes" ];

			# Avoid signature verification messages when doing remote builds
			trusted-users = [ "${config.users.users.aires.name}" ];
		};

		# Enable periodic nix store optimization
		optimise.automatic = true;

		# Configure NixOS to use the same software channel as Flakes
		registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
		nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

		# Configure remote build machines (mainly Haven)
		# To enable remote builds for a specific host, add `nix.distributedBuilds = true;` to its config
		buildMachines = [{ 
			hostName = "haven";
			systems = [
				"x86_64-linux"
				"aarch64-linux"
			];
			protocol = "ssh-ng";
			supportedFeatures = [
				"nixos-test"
				"kvm"
			];
		}];

		# When using a builder, use its package store
		extraOptions = ''
			builders-use-substitutes = true
		'';
	};
}