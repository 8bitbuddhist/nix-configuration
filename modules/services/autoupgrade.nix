# Run automatic updates. Replaces system.autoUpgrade.
{ config, lib, ... }:

let
  cfg = config.aux.system.services.autoUpgrade;
in
{
  options = {
    aux.system.services.autoUpgrade = {
      enable = lib.mkEnableOption (lib.mdDoc "Enables automatic system updates.");
      branches = lib.mkOption {
        type = lib.types.attrs;
        description = "Which local and remote branches to compare.";
        default = {
          local = "main";
          remote = "main";
          remoteName = "origin";
        };
      };
      configDir = lib.mkOption {
        type = lib.types.str;
        description = "Path where your NixOS configuration files are stored.";
      };
      onCalendar = lib.mkOption {
        default = "daily";
        type = lib.types.str;
        description = "How frequently to run updates. See systemd.timer(5) and systemd.time(7) for configuration details.";
      };
      persistent = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "If true, the time when the service unit was last triggered is stored on disk. When the timer is activated, the service unit is triggered immediately if it would have been triggered at least once during the time when the timer was inactive. This is useful to catch up on missed runs of the service when the system was powered down.";
      };
      pushUpdates = lib.mkEnableOption (
        lib.mdDoc "Updates the flake.lock file and pushes it back to the repo."
      );
      user = lib.mkOption {
        type = lib.types.str;
        description = "The user who owns the configDir.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Assert that system.autoUpgrade is not also enabled
      assertions = [
        {
          assertion = !config.system.autoUpgrade.enable;
          message = "The system.autoUpgrade option conflicts with this module.";
        }
      ];

      # Pull and apply updates.
      systemd.services."nixos-upgrade" = {
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        path = config.aux.system.corePackages;
        # Git diffing strategy courtesy of https://stackoverflow.com/a/40255467
        script = ''
          cd ${cfg.configDir}
          # Check if there are changes from Git.
          echo "Pulling latest version..."
          sudo -u ${cfg.user} git fetch
          sudo -u ${cfg.user} git diff --quiet --exit-code ${cfg.branches.local} ${cfg.branches.remoteName}/${cfg.branches.remote} || true
          # If we have changes (git diff returns 1), pull changes and run the update
          if [ $? -eq 1 ]; then
            echo "Updates found, running nixos-rebuild..."
            sudo -u ${cfg.user} git pull --recurse-submodules
            nixos-rebuild switch --flake .
          else
            echo "No updates found. Exiting."
          fi
        '';
      };
      systemd.timers."nixos-upgrade" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.onCalendar;
          Persistent = cfg.persistent;
          Unit = "nixos-upgrade.service";
        };
      };
    })
    (lib.mkIf cfg.pushUpdates {
      # Automatically update Flake configuration for other hosts to use
      systemd.services."nixos-upgrade-flake" = {
        serviceConfig = {
          Type = "oneshot";
          User = cfg.user;
        };
        path = config.aux.system.corePackages;
        script = ''
          set -eu
          cd ${cfg.configDir}
          # Make sure we're up-to-date
          echo "Pulling the latest version..."
          git pull --recurse-submodules
          nix flake update --commit-lock-file
          git push
        '';
      };

      systemd.timers."nixos-upgrade-flake" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = cfg.onCalendar;
          Persistent = cfg.persistent;
          Unit = "nixos-upgrade-flake.service";
        };
      };
    })
  ];
}
