{ config, lib, ... }:

let 
  cfg = config.host.apps.development;
in
with lib;
{
  options = {
    host.apps.development.enable = mkEnableOption (mdDoc "Enables development tools");
  };

  config = mkIf cfg.enable {
    host.ui.flatpak.enable = true;

    services.flatpak.packages = [
      "com.vscodium.codium"
			"dev.k8slens.OpenLens"
    ];
  };
}