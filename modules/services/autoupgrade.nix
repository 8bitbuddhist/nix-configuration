# Run automatic updates. Replaces system.autoUpgrade.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.host.services.autoUpgrade;
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
        path = with pkgs; [
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
        script = ''
          cd ${config.users.users.aires.home}/Development/nix-configuration
          # Check if there are changes from Git
          sudo -u aires git fetch
          sudo -u aires git diff --exit-code main origin/main
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
        path = with pkgs; [
          # Courtesy of https://discourse.nixos.org/t/how-to-use-other-packages-binary-in-systemd-service-configuration/14363
          coreutils
          gnutar
          xz.bin
          gzip
          git
          config.nix.package.out
          openssh
        ];
        script = ''
          set -eu
          cd ${config.secrets.nixConfigFolder}
          git pull --recurse-submodules
          nix flake update --commit-lock-file
          git push
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
