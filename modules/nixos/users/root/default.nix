{ namespace, ... }:
{
  home-manager.users.root = {
    imports = [ ../common/home-manager/zsh.nix ];

    home.stateVersion = "24.05";
    programs.zsh = {
      oh-my-zsh.theme = "kardan";
      shellAliases.nos = "nixos-operations-script";
    };
  };
}
