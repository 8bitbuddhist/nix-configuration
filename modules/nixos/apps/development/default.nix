{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.apps.development;
in
{
  options = {
    ${namespace}.apps.development = {
      enable = lib.mkEnableOption "Enables development tools";
      kubernetes.enable = lib.mkEnableOption "Enables kubectl, virtctl, and similar tools.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      ${namespace} = {
        packages = with pkgs; [
          nil # Nix Language server: https://github.com/oxalica/nil
          nix-prefetch-scripts
          zed-editor
        ];
        ui.flatpak = {
          enable = true;
          packages = [
            "com.vscodium.codium"
            "org.gnome.gitg"
          ];
        };
      };
    })
    (lib.mkIf cfg.kubernetes.enable {
      environment.systemPackages = with pkgs; [
        kubectl
        kubernetes-helm
        kubevirt # Virtctl command-line tool
      ];

      services.flatpak.packages = [ "dev.k8slens.OpenLens" ];
    })
  ];
}
