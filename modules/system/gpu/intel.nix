# Enables Intel GPU support.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.gpu.intel;
in
{
  options = {
    aux.system.gpu.intel.enable = lib.mkEnableOption (lib.mdDoc "Enables Intel GPU support.");
  };

  config = lib.mkIf cfg.enable {
    # Configuration options from NixOS-Hardware: https://github.com/NixOS/nixos-hardware/blob/master/common/gpu/intel/default.nix
    boot.initrd.kernelModules = [ "i915" ];

    environment.variables.VDPAU_DRIVER = "va_gl";

    hardware.opengl.extraPackages = with pkgs; [
      (
        if (lib.versionOlder (lib.versions.majorMinor lib.version) "23.11") then
          vaapiIntel
        else
          intel-vaapi-driver
      )
      libvdpau-va-gl
      intel-media-driver
    ];

    hardware.opengl.extraPackages32 = with pkgs.driversi686Linux; [
      (
        if (lib.versionOlder (lib.versions.majorMinor lib.version) "23.11") then
          vaapiIntel
        else
          intel-vaapi-driver
      )
      libvdpau-va-gl
      intel-media-driver
    ];
  };
}
