# Modules common to all systems
{
  pkgs,
  namespace,
  ...
}:

{
  ${namespace} = {
    # Install base packages
    packages = with pkgs; [
      fastfetch # Show a neat system statistics screen when opening a terminal
      htop # System monitor
      lm_sensors # System temperature monitoring
      zellij # Terminal multiplexer
    ];

    # Install the nos helper script
    nix.nixos-operations-script.enable = true;
  };

  programs = {
    # Install ZSH for all users
    zsh.enable = true;

    # Configure nano
    nano = {
      enable = true;
      syntaxHighlight = true;
      nanorc = ''
        set tabsize 4
        set softwrap
        set autoindent
        set indicator
      '';
    };
  };

  # Set nano as the default editor
  environment.variables."EDITOR" = "nano";

  # Set ZSH as the default shell
  users.defaultUserShell = pkgs.zsh;
}
