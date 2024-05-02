# Set up program defaults
{ config, ... }: {
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

		nh = {
			enable = true;
			flake = "${config.users.users.aires.home}/Development/nix-configuration";
			
			# Alternative garbage collection system to nix.gc.automatic
			clean = {
				enable = true;
				dates = "daily";
				extraArgs = "--keep-since 7d --keep 10";	# Keep the last 10 entries
			};
		};
	};
}