{
  lib,
  config,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.raid;
in
{

  options = {
    ${namespace}.raid = {
      enable = lib.mkEnableOption "Enables RAID support.";
      storage = {
        enable = lib.mkEnableOption "Enables support for the storage array.";
        mailAddr = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "Address to email in case of issues.";
          example = "admin@example.com";
        };
        keyFile = lib.mkOption {
          default = "";
          type = lib.types.str;
          description = "Path to the key file to use to auto-unlock the array.";
          example = "/home/user/storage.key";
        };
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable { boot.swraid.enable = true; })
    (lib.mkIf cfg.storage.enable {
      ${namespace}.raid.enable = true;
      boot.swraid.mdadmConf = ''
        ARRAY /dev/md/Sapana metadata=1.2 UUID=51076daf:efdb34dd:bce48342:3b549fcb
        MAILADDR ${cfg.storage.mailAddr}
      '';

      # Auto-unlock RAID array with a key file
      environment.etc."crypttab" = lib.mkIf (cfg.storage.keyFile != "") {
        text = "storage /dev/md/Sapana ${cfg.storage.keyFile} nofail,keyfile-timeout=5s";
      };
      fileSystems."/storage" = {
        device = "/dev/mapper/storage";
        options = [
          "nofail" # Keep booting even if the array fails to unlock
          "lazytime" # Reduce atime writes: https://wiki.archlinux.org/title/Fstab#atime_options
          "commit=60" # Increase commit interval to 60 seconds to reduce writes: https://wiki.archlinux.org/title/Ext4#Increasing_commit_interval
        ];
      };

      # Optimize RAID performance via udev rules
      # See https://serverfault.com/questions/579489/linux-what-is-stripe-cache-size-and-what-does-it-do
      services.udev.extraRules = ''
        	SUBSYSTEM=="block", KERNEL=="md*", ACTION=="change", TEST=="md/stripe_cache_size", ATTR{md/stripe_cache_size}="8192"
        	SUBSYSTEM=="block", KERNEL=="md*", ACTION=="change", TEST=="queue/read_ahead_kb", ATTR{md/read_ahead_kb}="8192"
      '';

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
