{ ... }: {
	imports = [
		./bluetooth.nix
		./bootloader.nix
		./network.nix
		./shell.nix
		./system.nix
	];
}