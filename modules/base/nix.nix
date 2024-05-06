# Nix configuration
{ pkgs, config, lib, inputs, ... }: {
	# Disable local documentation
	# This is a temporary workaround to get Auxolotl to build. See https://forum.aux.computer/t/rebuild-is-failing/497/30
	documentation.nixos.enable = false;

	nix = {
		settings = {
			# Enable Flakes
			experimental-features = [ "nix-command" "flakes" ];

			# Use Lix instead of Nix
			extra-substituters = [ "https://cache.lix.systems" ];
			trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];

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
