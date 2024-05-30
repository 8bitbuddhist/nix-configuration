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
  pathPks = with pkgs; [
    # Courtesy of https://discourse.nixos.org/t/how-to-use-other-packages-binary-in-systemd-service-configuration/14363
    coreutils
    gnutar
    xz.bin
    gzip
    git
    config.nix.package.out
    nh
    openssh
    sudo
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
      systemd.services."nixos-update" = {
        serviceConfig = {
          Type = "oneshot";
          User = "root";
        };
        path = pathPkgs;
        script = ''
          cd ${config.secret.nixConfigFolder}
          # Check if there are changes from Git.
          # Since we're running this as root, we need to su into the user who owns the config folder.
          sudo -u aires git fetch
          sudo -u aires git diff --exit-code main origin/main
          # If we have changes (git diff returns 1), pull changes and run the update
          if [ $? -eq 1 ]; then
            sudo -u aires git pull --recurse-submodules
            nh os switch
          fi
        '';
      };
      systemd.timers."nixos-update-timer" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = "true";
          Unit = "nixos-update.service";
        };
      };
    })
    (lib.mkIf cfg.pushUpdates {
      # Automatically update Flake configuration for other hosts to use
      systemd.services."nixos-update-flake" = {
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
          git pull --recurse-submodules
          nix flake update
          git add flake.lock
          # Only commit and push if the lock file has changed, otherwise quietly exit
          git diff --quiet && git diff --staged --quiet || git commit -am "Update flake.lock" && git push
        '';
      };

      systemd.timers."nixos-update-flake-timer" = {
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = "true";
          Unit = "nixos-update-flake.service";
        };
      };
    })
  ];
}
