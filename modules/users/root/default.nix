{ config, lib, ... }:
{
  # Give root user access to run remote builds
  home-manager.users.root = {
    home.stateVersion = "24.05";
    programs = {
      ssh = {
        enable = true;
        matchBlocks = config.secrets.users.root.sshConfig;
      };
      git.extraConfig = {
        safe.directory = "${config.secrets.nixConfigFolder}/.git";
      };
    };
  };
}
