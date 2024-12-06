# Modules common to all systems
{
  pkgs,
  ...
}:

{
  aux.system = {
    # Install base packages
    packages = with pkgs; [
      fastfetch # Show a neat system statistics screen when opening a terminal
      htop # System monitor
      lm_sensors # System temperature monitoring
      zellij # Terminal multiplexer
    ];

    # Install the nos helper script
    nixos-operations-script.enable = true;
  };

  programs = {
    # Install ZSH for all users
    zsh.enable = true;

    # Configure nano
    nano.nanorc = ''
      set tabsize 4
      set softwrap
      set autoindent
      set indicator
    '';
  };

  # Set ZSH as the default shell
  users.defaultUserShell = pkgs.zsh;
}
