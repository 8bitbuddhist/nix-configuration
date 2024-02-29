{ pkgs, ... }:

{
	# Install ZSH for all users
	programs.zsh.enable = true;
	users.defaultUserShell = pkgs.zsh;
}
