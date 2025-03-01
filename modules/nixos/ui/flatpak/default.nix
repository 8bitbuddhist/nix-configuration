{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:

# Flatpak support and options
let
  cfg = config.${namespace}.ui.flatpak;
in
{
  options = {
    ${namespace}.ui.flatpak = {
      enable = lib.mkEnableOption { description = "Enables Flatpak support."; };
      packages = lib.mkOption {
        description = "Flatpak packages to install.";
        type = lib.types.listOf lib.types.str;
        default = [
          "com.github.tchx84.Flatseal"
          "io.github.ungoogled_software.ungoogled_chromium"
          "org.mozilla.firefox"
        ];
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

        # Delete stale/unused packages
        uninstallUnused = true;

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
            paths = config.${namespace}.ui.desktops.themePackages;
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
          "/usr/share/fonts" = mkRoSymBind "${aggregatedFonts}/share/fonts";
        };
    })
  ];
}
