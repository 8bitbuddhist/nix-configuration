# System options
{
  pkgs,
  config,
  lib,
  ...
}:
{
  # Set up the environment
  environment = {
    # Install base packages
    systemPackages = with pkgs; [
      bash
      dconf # Needed to fix an issue with Home-manager. See https://github.com/nix-community/home-manager/issues/3113
      direnv
      git
      home-manager
      nano
      p7zip
      fastfetch
      nh # Nix Helper: https://github.com/viperML/nh
    ];

    variables = {
      EDITOR = "nano"; # Set default editor to nano
    };
  };

  # Configure automatic updates. Replaces system.autoUpgrade.
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
    ];
    script = ''
            cd ${config.users.users.aires.home}/Development/nix-configuration
			# Check if there are changes from Git
			sudo -u aires git fetch
			sudo -u aires git diff --exit-code main origin/main
			if [ $? -eq 1]; then
				sudo -u aires git pull --recurse-submodules
				nh os search
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

  services = {
    # Enable fwupd (firmware updater)
    fwupd.enable = true;

    # Autoscrub BTRFS partitions
    btrfs.autoScrub = lib.mkIf (config.fileSystems."/".fsType == "btrfs") {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/" ];
    };

    # Allow systemd user services to keep running after the user has logged out
    logind.killUserProcesses = false;

    # Enable disk monitoring
    smartd = {
      enable = true;
      autodetect = true;
      notifications.wall.enable = true;
    };
  };

  # Reduce logout stop timer duration
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
}
