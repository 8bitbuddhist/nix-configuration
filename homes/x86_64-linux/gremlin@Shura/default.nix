{
  namespace,
  osConfig,
  pkgs,
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

    # Install packages specific to Gremlin
    packages = with pkgs; [
      awscli2
      unstable.figma-linux
    ];

    # User account image
    file.".face".source = ./face.png;
  };

  programs = {
    # Let home Manager install and manage itself.
    home-manager.enable = true;

    # Set up SSH
    ssh = {
      enable = true;
      compression = true;
      matchBlocks = osConfig.${namespace}.secrets.users.gremlin.sshConfig;
    };

    # Tweak Zsh for Gremlin
    zsh.oh-my-zsh = {
      plugins = [
        "aws"
      ];
      theme = "gnzh";
    };
  };
}
