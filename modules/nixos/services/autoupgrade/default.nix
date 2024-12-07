# Run automatic updates. Replaces system.autoUpgrade.
{
  config,
  lib,
  namespace,
  ...
}:

let
  cfg = config.${namespace}.services.autoUpgrade;
in
{
  options = {
    ${namespace}.services.autoUpgrade = {
      enable = lib.mkEnableOption "Enables automatic system updates.";
      configDir = lib.mkOption {
        type = lib.types.str;
        description = "Path where your NixOS configuration files are stored.";
      };
      extraFlags = lib.mkOption {
        type = lib.types.str;
        description = "Extra flags to pass to nixos-rebuild.";
        default = "";
      };
      onCalendar = lib.mkOption {
        default = "daily";
        type = lib.types.str;
        description = "How frequently to run updates. See systemd.timer(5) and systemd.time(7) for configuration details.";
      };
      operation = lib.mkOption {
        type = lib.types.enum [
          "boot"
          "switch"
          "test"
        ];
        default = "switch";
        description = "Which `nixos-rebuild` operation to perform. Defaults to `switch`.";
      };
      persistent = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "If true, the time when the service unit was last triggered is stored on disk. When the timer is activated, the service unit is triggered immediately if it would have been triggered at least once during the time when the timer was inactive. This is useful to catch up on missed runs of the service when the system was powered down.";
      };
      pushUpdates = lib.mkEnableOption "Updates the flake.lock file and pushes it back to the repo.";
      user = lib.mkOption {
        type = lib.types.str;
        description = "The user who owns the configDir.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Assert that system.autoUpgrade is not also enabled
    assertions = [
      {
        assertion = !config.system.autoUpgrade.enable;
        message = "The system.autoUpgrade option conflicts with this module.";
      }
    ];

    # Deploy update script
    ${namespace}.nix.nixos-operations-script.enable = true;

    # Pull and apply updates.
    systemd = {
      services."nixos-upgrade" = {
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        path = config.${namespace}.corePackages;
        unitConfig.RequiresMountsFor = cfg.configDir;
        script =
          "/run/current-system/sw/bin/nixos-operations-script --operation ${cfg.operation} "
          + (if (cfg.configDir != "") then "--flake ${cfg.configDir} " else "")
          + (if (cfg.user != "") then "--user ${cfg.user} " else "")
          + (if (cfg.pushUpdates) then "--update " else "")
          + (if (cfg.extraFlags != "") then cfg.extraFlags else "");
      };
      timers."nixos-upgrade" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.onCalendar;
          Persistent = cfg.persistent;
          Unit = "nixos-upgrade.service";
          RandomizedDelaySec = "30m";
        };
      };
    };
  };
}
