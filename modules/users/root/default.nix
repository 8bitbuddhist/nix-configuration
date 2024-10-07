{ config, lib, ... }:
{
  # Give root user access to run remote builds
  home-manager.users.root = {
    home.stateVersion = "24.05";
    programs = {
      git.extraConfig = {
        safe.directory = "${config.secrets.nixConfigFolder}/.git";
      };
      ssh = {
        enable = true;
        matchBlocks = config.secrets.users.root.sshConfig;
      };
      zsh = {
        oh-my-zsh.theme = "kardan";
        shellAliases.nos = "nixos-operations-script";
      };
    };
  };
}
