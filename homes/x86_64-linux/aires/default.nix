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

    # Create .face file
    file.".face".source = ./face.png;
  };

  programs = {
    # Let home Manager install and manage itself.
    home-manager.enable = true;

    # Set up git
    git = {
      enable = true;
      userName = osConfig.${namespace}.secrets.users.aires.firstName;
      userEmail = osConfig.${namespace}.secrets.users.aires.email;
      extraConfig = {
        core.editor = osConfig.${namespace}.editor;
        merge.conflictStyle = "zdiff3";
        pull.ff = "only";
        push.autoSetupRemote = "true";
        safe.directory = "${osConfig.${namespace}.secrets.nixConfigFolder}/.git";
        submodule.recurse = true;
        credential.helper = "/run/current-system/sw/bin/git-credential-libsecret";
      };
    };

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
      loginExtra = ''
        fastfetch --memory-percent-green 75 --memory-percent-yellow 90
      '';
    };
  };

  # Run the SSH agent on login
  systemd.user.services."ssh-agent" = {
    Unit.Description = "Manually starts the SSH agent.";
    Service.ExecStart = ''
      eval "$(ssh-agent -s)"
    '';
    Install.WantedBy = [ "multi-user.target" ]; # starts after login
  };
}
