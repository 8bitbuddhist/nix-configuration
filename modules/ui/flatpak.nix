{
  nix-flatpak,
  pkgs,
  config,
  lib,
  ...
}:

# Flatpak support and options
let
  cfg = config.aux.system.ui.flatpak;
in
with lib;
{
  options = {
    aux.system.ui.flatpak = {
      enable = mkEnableOption (mdDoc "Enables Flatpak support.");
      packages = lib.mkOption {
        description = "Flatpak packages to install.";
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = lib.literalExpression "[ \"com.valvesoftware.Steam\" ]";
      };
      remotes = lib.mkOption {
        description = "The list of remote Flatpak repos to pull from. Includes Flathub by default.";
        type = lib.types.listOf lib.types.attrs;
        default = [
          {
            name = "flathub";
            location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
          }
        ];
      };
    };
  };

  config = mkIf cfg.enable {
    # Enable Flatpak
    services.flatpak = {
      enable = true;

      # Manage all Flatpak packages and remotes
      uninstallUnmanaged = true;

      # Enable automatic updates alongside nixos-rebuild
      update.onActivation = true;

      # Add remote(s)
      remotes = cfg.remotes;

      # Install base Flatpaks. For details, see https://github.com/gmodena/nix-flatpak
      packages = cfg.packages;
    };
  };
}
