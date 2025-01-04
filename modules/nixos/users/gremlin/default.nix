{
  lib,
  config,
  namespace,
  ...
}:

# Define 'gremlin' user
let
  cfg = config.${namespace}.users.gremlin;
in
{
  options = {
    ${namespace}.users.gremlin = {
      enable = lib.mkEnableOption "Enables gremlin user account";
    };
  };

  config = lib.mkIf cfg.enable {
    # Add Gremlin account
    users = {
      users.gremlin = {
        isNormalUser = true;
        description = "Gremlin";
        uid = 1001;
        hashedPassword = config.${namespace}.secrets.users.gremlin.hashedPassword;
        group = "gremlin";
        extraGroups = [
          "networkmanager"
          "input"
          "users"
        ];

        # Allow systemd services to keep running even while gremlin is logged out
        linger = true;
      };

      groups."gremlin" = {
        gid = 1001;
      };
    };

    # Install gremlin-specific flatpaks
    ${namespace}.ui.flatpak.packages = [
      "com.google.Chrome"
      "com.slack.Slack"
    ];

  };
}
