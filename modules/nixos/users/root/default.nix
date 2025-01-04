{ ... }:
{
  # FIXME: Dropping this into /homes/ causes a weird error that I don't know how to fix:
  #   "error: The option `users.users.root.shell' is defined multiple times while it's expected to be unique."
  # Keeping here for now.
  home-manager.users.root = {
    imports = [ ../../../../homes/common/zsh.nix ];

    home.stateVersion = "24.05";
    programs.zsh = {
      oh-my-zsh.theme = "kardan";
      shellAliases.nos = "nixos-operations-script";
    };
  };
}
