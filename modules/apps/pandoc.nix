{ pkgs, config, lib, ... }:

let
	cfg = config.host.apps.pandoc;
in
with lib;
{
	options = {
		host.apps.pandoc.enable = mkEnableOption (mdDoc "Enables pandoc");
	};

	config = mkIf cfg.enable {
		environment.systemPackages = with pkgs; [
			haskellPackages.pandoc
			haskellPackages.pandoc-cli
			haskellPackages.pandoc-crossref
			texliveSmall
		];
	};
}