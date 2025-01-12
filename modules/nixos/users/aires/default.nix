{
  lib,
  config,
  namespace,
  ...
}:

# Define 'aires'

# FIXME: Can't set osConfig in the /homes/ folder, so we unfortunately need to keep the system-level user configuration here.
let
  cfg = config.${namespace}.users.aires;
in
{
  options = {
    ${namespace}.users.aires = {
      enable = lib.mkEnableOption "Enables aires user account";
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.aires = {
        isNormalUser = true;
        description = "Aires";
        uid = 1000;
        hashedPassword = config.${namespace}.secrets.users.aires.hashedPassword;
        extraGroups = [
          "input"
          "networkmanager"
          "plugdev"
          "tss" # For access to TPM devices
          "wheel"
          "users"
          (lib.mkIf config.${namespace}.services.virtualization.host.enable "libvirtd")
        ];

        # Allow systemd services to run even while aires is logged out
        linger = true;

        # Allow these systems to log into aires' account via SSH (if enabled on the host)
        openssh.authorizedKeys.keys = with config.${namespace}.secrets.hosts; [
          hevana.ssh.publicKey
          khanda.ssh.publicKey
          shura.ssh.publicKey
        ];
      };

      groups."aires" = {
        gid = 1000;
      };
    };
  };
}
