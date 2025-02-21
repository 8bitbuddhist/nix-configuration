{
  config,
  namespace,
  pkgs,
  ...
}:

let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.11";
  hostName = "gremlin-lab";
in
{
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  # Functionality for Kubernetes in Docker
  virtualisation.docker = {
    enable = true;
    storageDriver = "btrfs";
    autoPrune.enable = true;
  };
  environment.systemPackages = with pkgs.unstable; [
    kind
    kubectl
    kubernetes-helm
    skaffold
  ];
  networking.firewall = {
    allowedTCPPorts = [ 80 ];
    # Required to get container <-> host networking.
    #   See https://github.com/NixOS/nixpkgs/issues/298165
    checkReversePath = false;
  };

  # Configure the system.
  ${namespace} = {
    # Enable Secure Boot support.
    bootloader = {
      enable = true;
      secureboot.enable = true;
      tpm2.enable = true;
    };

    # Enable GPU support.
    gpu = {
      intel.enable = true;
      nvidia = {
        enable = true;
        hybrid = {
          enable = true;
          busIDs.nvidia = "PCI:3:0:0";
          busIDs.intel = "PCI:0:2:0";
        };
      };
    };

    services = {
      autoUpgrade = {
        enable = true;
        pushUpdates = false;
        configDir = config.${namespace}.secrets.nixConfigFolder;
        onCalendar = "daily";
        user = config.users.users.aires.name;
      };
      ssh = {
        enable = true;
        ports = [ config.${namespace}.secrets.hosts.hevana.ssh.port ];
      };
      virtualization.host = {
        enable = true;
        vmBuilds = {
          enable = true;
          cores = 3;
          ram = 3072;
        };
      };
    };

    users.aires.enable = true;
  };
}
