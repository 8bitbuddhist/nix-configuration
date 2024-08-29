# Configures bluetooth.
{ lib, config, ... }:

let
  cfg = config.aux.system.raid;
in
{

  options = {
    aux.system.raid = {
      enable = lib.mkEnableOption "Enables RAID support.";
      sapana.enable = lib.mkEnableOption "Enables support for the Sapana/storage array.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable { boot.swraid.enable = true; })
    (lib.mkIf cfg.sapana.enable {
      aux.system.raid.enable = true;
      boot.swraid.mdadmConf = ''
        ARRAY /dev/md/Sapana metadata=1.2 UUID=51076daf:efdb34dd:bce48342:3b549fcb
        MAILADDR ${config.secrets.users.aires.email}
      '';
    })
  ];
}
