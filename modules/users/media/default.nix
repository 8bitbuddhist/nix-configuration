{
  pkgs,
  lib,
  config,
  ...
}:

# Define user for managing media on Haven
let
  cfg = config.host.users.media;
in
with lib;
{

  options = {
    host.users.media = {
      enable = mkEnableOption (mdDoc "Enables media user account");
    };
  };

  config = mkIf cfg.enable {
    users.groups."media" = {
      gid = 1001;
    };

    users.users.media = {
      isNormalUser = false;
      isSystemUser = true;
      description = "Media manager";
      uid = 1001;
      group = "media";
    };
  };
}
