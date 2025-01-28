{
  namespace,
  osConfig,
  ...
}:

{
  imports = [
    ../../common/git.nix
    ../../common/gnome.nix
    ../../common/zsh.nix
  ];

  home = {
    # The state version is required and should stay at the version you originally installed.
    stateVersion = "24.05";

    # Copy files ~/
    file = {
      # fastfetch config
      ".config/fastfetch/config.jsonc".source = ./fastfetch/fastfetch-config.jsonc;
      ".config/fastfetch/logo.txt".source = ./fastfetch/lion_ascii_smol.txt;

      # User account image
      ".face".source = ./face.png;
    };
  };

  programs = {
    # Let home Manager install and manage itself.
    home-manager.enable = true;

    # Set up SSH
    ssh = {
      enable = true;
      matchBlocks = osConfig.${namespace}.secrets.users.aires.sshConfig;
    };

    # Set up Zsh
    zsh = {
      oh-my-zsh = {
        theme = "gentoo";
      };
      shellAliases = {
        com = "compile-manuscript";
        nos = "nixos-operations-script";
        z = "zellij";
        update = "upgrade";
        upgrade = "nos --update";
      };
      loginExtra = "fastfetch";
    };
  };
}
