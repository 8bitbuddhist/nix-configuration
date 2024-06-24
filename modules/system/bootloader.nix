# Configuration options specific to bootloader management.
# SecureBoot is handled via Lanzaboote. See https://github.com/nix-community/lanzaboote
{
  config,
  lib,
  pkgs,
  ...
}:

# Bootloader
let
  cfg = config.aux.system.bootloader;
in
{

  options = {
    aux.system.bootloader = {
      enable = lib.mkOption {
        description = "Automatically configures the bootloader. Set to false to configure manually.";
        type = lib.types.bool;
        default = true;
      };

      secureboot.enable = lib.mkEnableOption (lib.mdDoc "Enables Secureboot support.");
      tpm2.enable = lib.mkEnableOption (lib.mdDoc "Enables TPM2 support.");
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.secureboot.enable {
        boot = {
          # Enable Secure Boot
          bootspec.enable = true;

          # Use Lanzaboote in place of systemd-boot.
          loader.systemd-boot.enable = false;
          loader.efi.canTouchEfiVariables = true;
          lanzaboote = {
            enable = true;
            pkiBundle = "/etc/secureboot";
          };
        };
      })

      # Set up TPM if enabled. See https://nixos.wiki/wiki/TPM
      (lib.mkIf (cfg.tpm2.enable) {
        # After installing and rebooting, set it up via https://wiki.archlinux.org/title/Systemd-cryptenroll#Trusted_Platform_Module
        environment.systemPackages = with pkgs; [ tpm2-tss ];
        security.tpm2 = {
          enable = true;
          pkcs11.enable = true;
          tctiEnvironment.enable = true;
        };
      })

      # Use the default systemd-boot bootloader.
      (lib.mkIf (!cfg.secureboot.enable) {
        boot.loader = {
          systemd-boot.enable = true;
          efi.canTouchEfiVariables = true;
        };
      })
    ]
  );
}
