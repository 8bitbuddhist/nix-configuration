{lib, ...}:

with lib;
{
	imports = [
		./server.nix
		./workstation.nix
	];

	options = {
		host.role = mkOption {
			type = types.enum [
				"server"
				"workstation"
			];
		};
	};
}