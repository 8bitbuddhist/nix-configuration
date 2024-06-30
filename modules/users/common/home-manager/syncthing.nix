{
  username,
  configDir,
  port ? 8080,
  autostart ? false,
  enableTray ? false,
  lib,
  pkgs,
  config,
  ...
}:

{
  config = {
    users.users.${username}.packages = [
      pkgs.syncthing
      (lib.mkIf enableTray pkgs.syncthingtray)
    ];

    # Open port 8080
    networking.firewall.allowedTCPPorts = [ port ];

    home-manager.users.${username} = {
      # Syncthing options
      services.syncthing = {
        enable = true;
        extraOptions = [
          "--gui-address=0.0.0.0:${port}"
          "--home=${configDir}/.config/syncthing"
          "--no-default-folder"
        ];
      };

      # Override the default Syncthing settings so it doesn't start on boot
      systemd.user.services."syncthing" = lib.mkIf (!autostart) { Install = lib.mkForce { }; };
    };
  };
}
