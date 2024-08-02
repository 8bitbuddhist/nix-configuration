{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.apps.development;
in
{
  options = {
    aux.system.apps.development = {
      enable = lib.mkEnableOption "Enables development tools";
      kubernetes.enable = lib.mkEnableOption "Enables kubectl, virtctl, and similar tools.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      aux.system = {
        packages = with pkgs; [ nixd ];
        ui.flatpak = {
          enable = true;
          packages = [ "com.vscodium.codium" ];
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
