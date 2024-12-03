# Modules common to all systems
{
  inputs,
  pkgs,
  ...
}:

{
  # Install base packages
  aux.system.packages = with pkgs; [
    fastfetch # Show a neat system statistics screen when opening a terminal
    htop # System monitor
    lm_sensors # System temperature monitoring
    zellij # Terminal multiplexer
  ];

  # Install the nos helper script
  aux.system.nixos-operations-script.enable = true;

  # Allow packages from the unstable repo by using 'pkgs.unstable'
  nixpkgs.overlays = [
    (final: _prev: {
      unstable = import inputs.nixpkgs-unstable {
        system = final.system;
        config.allowUnfree = true;
      };
    })
  ];

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
