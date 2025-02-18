{
  config,
  namespace,
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

  # Configure the system.
  ${namespace} = {
    # Enable Secure Boot support.
    bootloader = {
      enable = true;
      secureboot.enable = true;
      tpm2.enable = true;
    };

    # Change the default text editor. Options are "emacs", "nano", or "vim".
    editor = "nano";

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
        pushUpdates = true; # ...but do push updates remotely.
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
