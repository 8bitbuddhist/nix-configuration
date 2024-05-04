{lib, ...}:

with lib;
{
	options = {
		host.role = mkOption {
			type = types.enum [
				"server"
				"workstation"
			];
		};
	};
}