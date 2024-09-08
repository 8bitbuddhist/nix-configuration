{
  pkgs,
  config,
  lib,
  ...
}:

# Flatpak support and options
let
  cfg = config.aux.system.ui.flatpak;
in
{
  options = {
    aux.system.ui.flatpak = {
      enable = lib.mkEnableOption { description = "Enables Flatpak support."; };
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
      useBindFS = lib.mkEnableOption "Whether to use a BindFS mount to support custom themes and cursors. May cause performance issues.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
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
    })
    (lib.mkIf cfg.useBindFS {
      # Workaround for getting Flatpak apps to use system fonts, icons, and cursors
      # For details (and source), see https://github.com/NixOS/nixpkgs/issues/119433#issuecomment-1767513263
      # NOTE: If fonts in Flatpaks appear incorrect (like squares), run this command to regenerate the font cache:
      #  flatpak list --columns=application | xargs -I %s -- flatpak run --command=fc-cache %s -f -v
      system.fsPackages = [ pkgs.bindfs ];
      fileSystems =
        let
          mkRoSymBind = path: {
            device = path;
            fsType = "fuse.bindfs";
            options = [
              "ro"
              "resolve-symlinks"
              "x-gvfs-hide"
            ];
          };
          aggregatedIcons = pkgs.buildEnv {
            name = "system-icons";
            paths = with pkgs; [
              (lib.mkIf config.aux.system.ui.desktops.gnome.enable gnome-themes-extra)
              (lib.mkIf config.aux.system.ui.desktops.kde.enable kdePackages.breeze-icons)
              papirus-icon-theme
              qogir-icon-theme
            ];
            pathsToLink = [ "/share/icons" ];
          };
          aggregatedFonts = pkgs.buildEnv {
            name = "system-fonts";
            paths = config.fonts.packages;
            pathsToLink = [ "/share/fonts" ];
          };
        in
        {
          "/usr/share/icons" = mkRoSymBind "${aggregatedIcons}/share/icons";
          "/usr/local/share/fonts" = mkRoSymBind "${aggregatedFonts}/share/fonts";
        };
    })
  ];
}
