{
  pkgs,
  lib,
  config,
  ...
}:

# Define 'gremlin' user
let
  cfg = config.aux.system.users.gremlin;
in
{
  options = {
    aux.system.users.gremlin = {
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
        hashedPassword = config.secrets.users.gremlin.hashedPassword;
        extraGroups = [
          "networkmanager"
          "input"
        ];

        # Allow systemd services to keep running even while gremlin is logged out
        linger = true;
      };

      # Install gremlin-specific flatpaks
      aux.system.ui.flatpak.packages = [
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
            matchBlocks = config.secrets.users.gremlin.sshConfig;
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
