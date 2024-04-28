{ config, lib, pkgs, ... }:

# Bootloader
let
	cfg = config.host.boot;
in
with lib;
{

	options = {
		host.boot = {
			enable = mkOption {
				description = "Automatically configures the bootloader. Set to false to configure manually.";
				type = types.bool;
				default = true;
			};
		
			secureboot.enable = mkOption {
				description = "Enables Secureboot";
				type = types.bool;
				default = true;
			};
		};
	};

	config = mkIf cfg.enable (mkMerge[
		(mkIf cfg.secureboot.enable {
			boot = {
				# Enable Secure Boot
				bootspec.enable = true;
				
				# Disable systemd-boot. We lanzaboote now.
				loader.systemd-boot.enable = false;
				loader.efi.canTouchEfiVariables = true;
				lanzaboote = {
					enable = true;
					pkiBundle = "/etc/secureboot";
				};
			};

			# Set up TPM. See https://nixos.wiki/wiki/TPM
			# After installing and rebooting, set it up via https://wiki.archlinux.org/title/Systemd-cryptenroll#Trusted_Platform_Module
			environment.systemPackages = with pkgs; [ tpm2-tss ];
			security.tpm2 = {
				enable = true;
				pkcs11.enable = true;
				tctiEnvironment.enable = true;
			};
		})

		# Plain boot
		(mkIf (!cfg.secureboot.enable) {
			boot = {
				loader.systemd-boot.enable = true;
				loader.efi.canTouchEfiVariables = true;
			};
		})
	]);
}
