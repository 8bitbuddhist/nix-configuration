{ ... }: {
	imports = [
		./apcupsd.nix
		./duplicacy-web.nix
		./fprintd.nix
		./k3s.nix
		./msmtp.nix
	];
}