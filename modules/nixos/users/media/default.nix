{
  lib,
  config,
  namespace,
  ...
}:

# Define user for managing media files
let
  cfg = config.${namespace}.users.media;
in
{

  options = {
    ${namespace}.users.media = {
      enable = lib.mkEnableOption "Enables media user account";
    };
  };

  config = lib.mkIf cfg.enable {
    users = {
      users.media = {
        isNormalUser = false;
        isSystemUser = true;
        description = "Media manager";
        uid = 1001;
        group = "media";
      };

      groups."media" = {
        gid = 1001;
      };
    };
  };
}
