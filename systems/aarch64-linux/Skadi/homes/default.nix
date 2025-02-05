{
  namespace,
  osConfig,
  pkgs,
  ...
}:
{
  # Read home-manager changelog before changing this value
  home.stateVersion = "24.05";

  home = {
    file.".nanorc" = {
      enable = true;
      text = ''
        include ${pkgs.nano}/share/nano/*.nanorc
        set tabsize 4
        set softwrap
        set autoindent
        set indicator
      '';
    };
  };

  # insert home-manager config
  programs = {
    command-not-found.enable = true;

    git = {
      enable = true;
      userName = osConfig.${namespace}.secrets.users.aires.firstName;
      userEmail = osConfig.${namespace}.secrets.users.aires.email;
      merge.conflictStyle = "zdiff3";
      pull.ff = "only";
      push.autoSetupRemote = "true";
    };

    # Set up SSH
    ssh = {
      enable = true;
      matchBlocks = osConfig.${namespace}.secrets.users.aires.sshConfig;
    };

    zsh = {
      enable = true;
      enableAutosuggestions = true; # Had to use the old name, otherwise nix-on-droid complains it doesn't exist
      syntaxHighlighting.enable = true;
      history.ignoreDups = true; # Do not enter command lines into the history list if they are duplicates of the previous event.
      prezto = {
        git.submoduleIgnore = "untracked"; # Ignore submodules when they are untracked.
      };
      plugins = [
        {
          name = "zsh-nix-shell";
          file = "nix-shell.plugin.zsh";
          src = pkgs.fetchFromGitHub {
            owner = "chisui";
            repo = "zsh-nix-shell";
            rev = "v0.8.0";
            sha256 = "1lzrn0n4fxfcgg65v0qhnj7wnybybqzs4adz7xsrkgmcsr0ii8b7";
          };
        }
      ];
      oh-my-zsh = {
        enable = true;
        theme = "gentoo";
        plugins = [
          "command-not-found"
          "cp"
          "direnv"
          "dotenv"
          "extract"
          "git"
          "systemd"
        ];
      };
      shellAliases = {
        z = "zellij";
        update = "upgrade";
        upgrade = "nix-on-droid switch --flake ~/nix-configuration";
      };
    };
  };
}
