{
  pkgs,
  lib,
  config,
  namespace,
  ...
}:

# Define 'gremlin' user
let
  cfg = config.${namespace}.users.gremlin;
in
{
  options = {
    ${namespace}.users.gremlin = {
      enable = lib.mkEnableOption "Enables gremlin user account";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Add Gremlin account
      users.users.gremlin = {
        isNormalUser = true;
        description = "Gremlin";
        uid = 1001;
        hashedPassword = config.${namespace}.secrets.users.gremlin.hashedPassword;
        extraGroups = [
          "networkmanager"
          "input"
          "groups"
        ];

        # Allow systemd services to keep running even while gremlin is logged out
        linger = true;
      };

      # Install gremlin-specific flatpaks
      ${namespace}.ui.flatpak.packages = [
        "com.google.Chrome"
        "com.slack.Slack"
      ];

      home-manager.users.gremlin = {
        imports = [
          ../common/home-manager/gnome.nix
          ../common/home-manager/zsh.nix
        ];

        home = {
          # Basic setup
          username = "gremlin";
          homeDirectory = "/home/gremlin";

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

          # Set up git to match Aires' configuration
          git = config.home-manager.users.aires.programs.git;

          # Set up SSH
          ssh = {
            enable = true;
            matchBlocks = config.${namespace}.secrets.users.gremlin.sshConfig;
          };

          # Set up Zsh
          zsh = {
            oh-my-zsh = {
              theme = "gnzh";
            };
          };
        };
      };
    })
  ];
}
