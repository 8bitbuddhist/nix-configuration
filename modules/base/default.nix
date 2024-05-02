{ ... }: {
	imports = [
		./bluetooth.nix
		./bootloader.nix
		./network.nix
		./nix.nix
		./programs.nix
		./shell.nix
		./system.nix
	];
}