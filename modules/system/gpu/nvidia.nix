# Enables Nvidia GPU support.
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system.gpu.nvidia;
in
{
  options = {
    aux.system.gpu.nvidia = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables Nvidia GPU support.");
      hybrid = {
        enable = lib.mkEnableOption (lib.mdDoc "Enables hybrid GPU support.");
        sync = lib.mkEnableOption (
          lib.mdDoc "Enables sync mode for faster performance at the cost of higher battery usage."
        );
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

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (cfg.busIDs.nvidia == "");
        message = "You need to define a bus ID for your Nvidia GPU. To learn how to find the bus ID, see https://nixos.wiki/wiki/Nvidia#Configuring_Optimus_PRIME:_Bus_ID_Values_.28Mandatory.29.";
      }
      {
        assertion = (cfg.busIDs.intel == "" && cfg.busIDs.amd == "");
        message = "You need to define a bus ID for your non-Nvidia GPU. To learn how to find your bus ID, see https://nixos.wiki/wiki/Nvidia#Configuring_Optimus_PRIME:_Bus_ID_Values_.28Mandatory.29.";
      }
    ];

    aux.system.allowUnfree = true;

    services.xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
    hardware.opengl.extraPackages = with pkgs; [ vaapiVdpau ];

    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = lib.mkIf (config.aux.system.ui.desktops.enable) true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      prime = lib.mkIf cfg.hybrid.enable {

        offload = lib.mkIf (!cfg.hybrid.sync) {
          enable = true;
          enableOffloadCmd = true; # Provides `nvidia-offload` command.
        };

        sync.enable = lib.mkIf cfg.hybrid.sync true;

        nvidiaBusId = cfg.hybrid.busIDs.nvidia;
        intelBusId = lib.mkIf (cfg.hybrid.busIDs.intel != "") cfg.hybrid.busIDs.intel;
        amdgpuBusId = lib.mkIf (cfg.hybrid.busIDs.amd != "") cfg.hybrid.busIDs.amd;
      };
    };
  };
}
