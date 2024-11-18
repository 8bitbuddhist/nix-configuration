# Enables AMD GPU support.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.gpu.amd;
in
{
  options = {
    aux.system.gpu.amd.enable = lib.mkEnableOption "Enables AMD GPU support.";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.graphics = {
      enable = true;
      # 32-bit application compatibility
      enable32Bit = true;
    };
  };
}
