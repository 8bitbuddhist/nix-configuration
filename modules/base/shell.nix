{ pkgs, ... }:

{
	# Install ZSH for all users
	programs.zsh.enable = true;
	users.defaultUserShell = pkgs.zsh;

	# Show a neat system statistics screen when opening a terminal
	environment.systemPackages = with pkgs; [ fastfetch ];
}
