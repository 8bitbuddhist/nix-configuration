{ ... }: {
	imports = [
		./bluetooth.nix
		./bootloader.nix
		./network.nix
		./nix.nix
		./shell.nix
		./system.nix
	];
}