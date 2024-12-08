# Template file for configuring a new host
{
  namespace,
  ...
}:
let
  # Do not change this value! This tracks when NixOS was installed on your system.
  stateVersion = "24.11";
  # The hostname for this system.
  hostName = "myHost";
in
{
  # Generate hardware-configuration.nix by running this command on the host:
  #   $ nixos-generate-config
  imports = [ ./hardware-configuration.nix ];

  system.stateVersion = stateVersion;
  networking.hostName = hostName;

  # Main system configuration happens here.
  config.${namespace} = {
    apps = {
      # Define applications here
    };
    services = {
      # Define services here
    };
    users.aires = {
      enable = true;
      services.syncthing = {
        enable = true;
        home = "/home/aires/.config/syncthing";
      };
    };
  };

  # Additional configuration options go here
}
