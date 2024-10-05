# Enables Intel GPU support.
# https://wiki.nixos.org/wiki/Intel_Graphics
# https://nixos.org/manual/nixos/stable/#sec-x11--graphics-cards-intel
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
    aux.system.gpu.intel.enable = lib.mkEnableOption "Enables Intel GPU support.";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = [ "intel" ];

    hardware.graphics = {
      enable = true;
      extraPackages = [
        pkgs.intel-media-driver
        pkgs.unstable.vpl-gpu-rt
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        intel-media-driver
        pkgs.unstable.vpl-gpu-rt
      ];
    };
  };
}
