# Run automatic updates. Replaces system.autoUpgrade.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.host.services.autoUpgrade;

  # List of packages to include in each service's $PATH
  pathPkgs = with pkgs; [
    # Courtesy of https://discourse.nixos.org/t/how-to-use-other-packages-binary-in-systemd-service-configuration/14363
    coreutils
    git
    gnutar
    gzip
    config.nix.package.out
    nh
    config.programs.ssh.package
    sudo
    xz.bin
  ];
in
{
  options = {
    host.services.autoUpgrade = {
      enable = lib.mkOption {
        default = true;
        type = lib.types.bool;
        description = "Enables automatic system updates.";
      };
      pushUpdates = lib.mkEnableOption (
        lib.mdDoc "Updates the flake.lock file and pushes it back to the repo."
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # Pull and apply updates.
      systemd.services."nixos-upgrade" = {
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        path = pathPkgs;
        script = ''
          cd ${config.secrets.nixConfigFolder}
          # Check if there are changes from Git.
          echo "Pulling latest version..."
          sudo -u aires git fetch
          sudo -u aires git diff --quiet --exit-code main origin/main || true
          # If we have changes (git diff returns 1), pull changes and run the update
          if [ $? -eq 1 ]; then
            echo "Updates found, running nixos-rebuild..."
            sudo -u aires git pull --recurse-submodules
            nh os switch
          else
            echo "No updates found. Exiting."
          fi
        '';
      };
      systemd.timers."nixos-upgrade-timer" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = "true";
          Unit = "nixos-upgrade.service";
        };
      };
    })
    (lib.mkIf cfg.pushUpdates {
      # Automatically update Flake configuration for other hosts to use
      systemd.services."nixos-upgrade-flake" = {
        serviceConfig = {
          Type = "oneshot";
          User = config.users.users.aires.name;
        };
        path = pathPkgs;
        # Git diffing strategy courtesy of https://stackoverflow.com/a/40255467
        script = ''
          set -eu
          cd ${config.secrets.nixConfigFolder}
          # Make sure we're up-to-date
          echo "Pulling the latest version..."
          git pull --recurse-submodules
          nix flake update --commit-lock-file
          git push
        '';
      };

      systemd.timers."nixos-upgrade-flake-timer" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = "true";
          Unit = "nixos-upgrade-flake.service";
        };
      };
    })
  ];
}
