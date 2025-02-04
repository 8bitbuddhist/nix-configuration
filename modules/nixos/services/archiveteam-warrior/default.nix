# Module for running Warrior from ArchiveTeam
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.archiveteam-warrior;

  UID = 8001;
  GID = 8001;
in
{
  options = {
    ${namespace}.services.archiveteam-warrior = {
      enable = lib.mkEnableOption "Enables Warrior.";
      home = lib.mkOption {
        default = "/var/lib/archiveteam/warrior";
        type = lib.types.str;
        description = "Where to store Warrior's files.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = "archiveteam";
        description = "User account under which Warrior runs.";
      };
      group = lib.mkOption {
        type = lib.types.str;
        default = "archiveteam";
        description = "Group under which Warrior runs.";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 8001;
        description = "Which port to run Warrior on. Set to 0 to disable host port binding.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace}.services.virtualization.containers.enable = true;

    users = {
      users.${cfg.user} = {
        uid = UID;
        description = "ArchiveTeam Warrior user";
        isSystemUser = true;
        group = cfg.group;
      };
      groups.${cfg.group}.gid = GID;
    };

    virtualisation.oci-containers.containers = {
      archiveteam-warrior = {
        image = "atdr.meo.ws/archiveteam/warrior-dockerfile";
        user = "${builtins.toString UID}:${builtins.toString GID}";
        volumes = [
          "${cfg.home}/data:/home/warrior/data"
          "${cfg.home}/projects:/home/warrior/projects"
        ];
        extraOptions = [ "--label=io.containers.autoupdate=registry" ];
        ports = lib.mkIf (cfg.port > 0) [
          "8001:${builtins.toString cfg.port}"
        ];
      };
    };

    systemd = {
      # Set permissions for home folder
      tmpfiles.rules = [ "Z ${cfg.home} ${builtins.toString UID} ${builtins.toString GID} - -" ];

      # Tell systemd to wait for the module's configuration directory to be available before starting the service.
      services.archiveteam-warrior.unitConfig.RequiresMountsFor = cfg.home;
    };
  };
}
