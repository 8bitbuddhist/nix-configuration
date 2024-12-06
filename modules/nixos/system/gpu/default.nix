# Enables AMD GPU support.
{
  pkgs,
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.gpu;
in
{
  options = {
    ${namespace}.gpu = {
      amd.enable = lib.mkEnableOption "Enables AMD GPU support.";
      intel.enable = lib.mkEnableOption "Enables Intel GPU support.";
      nvidia = {
        enable = lib.mkEnableOption "Enables Nvidia GPU support.";
        hybrid = {
          enable = lib.mkEnableOption "Enables hybrid GPU support.";
          sync = lib.mkEnableOption "Enables sync mode for faster performance at the cost of higher battery usage.";
          busIDs = {
            nvidia = lib.mkOption {
              description = "The bus ID for your Nvidia GPU.";
              type = lib.types.str;
              example = "PCI:0:2:0";
              default = "";
            };
            intel = lib.mkOption {
              description = "The bus ID for your integrated Intel GPU. If you don't have an Intel GPU, you can leave this blank.";
              type = lib.types.str;
              example = "PCI:14:0:0";
              default = "";
            };
            amd = lib.mkOption {
              description = "The bus ID for your integrated AMD GPU. If you don't have an AMD GPU, you can leave this blank.";
              type = lib.types.str;
              example = "PCI:54:0:0";
              default = "";
            };
          };
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.amd.enable {
      boot.initrd.kernelModules = [ "amdgpu" ];
      services.xserver.videoDrivers = [ "amdgpu" ];

      hardware.graphics = {
        enable = true;
        # 32-bit application compatibility
        enable32Bit = true;
      };
    })

    (lib.mkIf cfg.intel.enable {
      services.xserver.videoDrivers = [ "intel" ];

      hardware.graphics = {
        enable = true;
        extraPackages = with pkgs; [
          intel-media-driver
          vpl-gpu-rt
        ];
        extraPackages32 = with pkgs.driversi686Linux; [
          intel-media-driver
          vpl-gpu-rt
        ];
      };
    })
    (lib.mkIf cfg.nvidia.enable {
      assertions = [
        {
          assertion = (cfg.nvidia.hybrid.busIDs.nvidia != "");
          message = "You need to define a bus ID for your Nvidia GPU. To learn how to find the bus ID, see https://wiki.nixos.org/wiki/Nvidia#Configuring_Optimus_PRIME:_Bus_ID_Values_.28Mandatory.29.";
        }
        {
          assertion = (cfg.nvidia.hybrid.busIDs.intel != "" || cfg.nvidia.hybrid.busIDs.amd != "");
          message = "You need to define a bus ID for your non-Nvidia GPU. To learn how to find your bus ID, see https://wiki.nixos.org/wiki/Nvidia#Configuring_Optimus_PRIME:_Bus_ID_Values_.28Mandatory.29.";
        }
      ];

      services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
      hardware = {
        opengl.extraPackages = with pkgs; [ vaapiVdpau ];
        nvidia = {
          modesetting.enable = true;
          nvidiaSettings = config.${namespace}.ui.desktops.enable;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
          prime = lib.mkIf cfg.nvidia.hybrid.enable {

            offload = lib.mkIf (!cfg.nvidia.hybrid.sync) {
              enable = true;
              enableOffloadCmd = true; # Provides `nvidia-offload` command.
            };

            sync.enable = cfg.nvidia.hybrid.sync;

            nvidiaBusId = cfg.nvidia.hybrid.busIDs.nvidia;
            intelBusId = cfg.nvidia.hybrid.busIDs.intel;
            amdgpuBusId = cfg.nvidia.hybrid.busIDs.amd;
          };
        };
      };
    })
  ];
}
