{ lib, config, ... }:
let
  cfg = config.aux.system.raid;
in
{

  options = {
    aux.system.raid = {
      enable = lib.mkEnableOption "Enables RAID support.";
      storage.enable = lib.mkEnableOption "Enables support for the storage array.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable { boot.swraid.enable = true; })
    (lib.mkIf cfg.storage.enable {
      aux.system.raid.enable = true;
      boot.swraid.mdadmConf = ''
        ARRAY /dev/md/Sapana metadata=1.2 UUID=51076daf:efdb34dd:bce48342:3b549fcb
        MAILADDR ${config.secrets.users.aires.email}
      '';

      # Auto-unlock RAID array with a key file
      environment.etc."crypttab".text = ''
        storage /dev/md/Sapana ${config.secrets.devices.storage.keyFile.path} nofail,keyfile-timeout=5s
      '';
      fileSystems."/storage" = {
        device = "/dev/mapper/storage";
        # Keep booting even if the array fails to unlock
        options = [ "nofail" ];
      };

      # Automatically scrub the array monthly
      systemd = {
        services."raid-scrub" = {
          description = "Periodically scrub RAID volumes for errors.";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
          script = "echo check > /sys/block/md127/md/sync_action";
        };
        timers."raid-scrub" = {
          description = "Periodically scrub RAID volumes for errors.";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "monthly";
            Persistent = true;
            Unit = "raid-scrub.service";
          };
        };
      };
    })
  ];
}
