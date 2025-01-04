{
  config,
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

    # Set environment variables
    sessionVariables = {
      KUBECONFIG = "/home/gremlin/.kube/config";
    };

    # Install packages specific to Gremlin
    packages = [
      pkgs.awscli2
      pkgs.unstable.figma-linux
    ];

    # Create .face file
    file.".face".source = ./face.png;
  };

  programs = {
    # Let home Manager install and manage itself.
    home-manager.enable = true;

    # Set up SSH
    ssh = {
      enable = true;
      matchBlocks = osConfig.${namespace}.secrets.users.gremlin.sshConfig;
    };

    # Set up Zsh
    zsh = {
      oh-my-zsh = {
        theme = "gnzh";
      };
    };
  };
}
