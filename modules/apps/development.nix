{ config, lib, pkgs, ... }:

let 
	cfg = config.host.apps.development;
in
with lib;
{
	options = {
		host.apps.development = {
			enable = mkEnableOption (mdDoc "Enables development tools");
			kubernetes.enable = mkEnableOption (mdDoc "Enables kubectl, virtctl, and similar tools.");
		};
	};

	config = mkMerge [
		(mkIf cfg.enable {
			host.ui.flatpak.enable = true;

			services.flatpak.packages = [
				"com.vscodium.codium"
				"dev.k8slens.OpenLens"
			];
		})
		(mkIf (cfg.kubernetes.enable) {
			environment.systemPackages = with pkgs; [
				kubectl
				kubernetes-helm
				kubevirt	# Virtctl command-line tool
			];
		})
	];
}