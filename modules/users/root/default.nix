{ ... }:
{
  home-manager.users.root = {
    home.stateVersion = "24.05";
    programs.zsh = {
      oh-my-zsh.theme = "kardan";
      shellAliases.nos = "nixos-operations-script";
    };
  };
}
