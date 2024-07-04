{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system.apps.development;
in
with lib;
{
  options = {
    aux.system.apps.development = {
      enable = mkEnableOption (mdDoc "Enables development tools");
      kubernetes.enable = mkEnableOption (mdDoc "Enables kubectl, virtctl, and similar tools.");
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      aux.system = {
        packages = with pkgs; [ nixd ];
        ui.flatpak = {
          enable = true;
          packages = [ "com.vscodium.codium" ];
        };
      };
    })
    (mkIf cfg.kubernetes.enable {
      environment.systemPackages = with pkgs; [
        kubectl
        kubernetes-helm
        kubevirt # Virtctl command-line tool
      ];

      services.flatpak.packages = [ "dev.k8slens.OpenLens" ];
    })
  ];
}
