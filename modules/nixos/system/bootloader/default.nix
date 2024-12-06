# Configuration options specific to bootloader management.
# SecureBoot is handled via Lanzaboote. See https://github.com/nix-community/lanzaboote
{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:

# Bootloader
let
  cfg = config.${namespace}.bootloader;
in
{

  options = {
    ${namespace}.bootloader = {
      enable = lib.mkOption {
        description = "Automatically configures the bootloader. Set to false to configure manually.";
        type = lib.types.bool;
        default = true;
      };

      secureboot.enable = lib.mkEnableOption "Enables Secureboot support (please read the README before enabling!).";
      tpm2.enable = lib.mkEnableOption "Enables TPM2 support.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf cfg.secureboot.enable {
        boot = {
          # Enable Secure Boot
          bootspec.enable = true;

          # Use Lanzaboote in place of systemd-boot.
          loader = {
            systemd-boot.enable = false;
            efi.canTouchEfiVariables = true;
          };
          lanzaboote = {
            enable = true;
            pkiBundle = "/etc/secureboot";
          };
        };
      })

      # Set up TPM if enabled. See https://wiki.nixos.org/wiki/TPM
      (lib.mkIf (cfg.tpm2.enable) {
        boot.initrd = {
          # Enable modules and support for TPM auto-unlocking
          systemd.enable = true;
          availableKernelModules = [ "tpm_crb" ];
          kernelModules = [ "tpm_crb" ];
        };
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
