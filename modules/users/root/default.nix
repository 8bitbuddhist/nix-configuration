{
  config,
  home-manager,
  lib,
  ...
}:
{
  # Give root user access to run remote builds
  home-manager.users.root = {
    home.stateVersion = "24.05";
    programs.ssh = lib.mkIf config.nix.distributedBuilds {
      enable = true;
      matchBlocks = config.secrets.users.root.sshConfig;
    };
  };
}
