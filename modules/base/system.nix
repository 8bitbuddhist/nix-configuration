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

  # Configure automatic updates for all hosts
  host.services.autoUpgrade = {
    enable = true;
    configDir = config.secrets.nixConfigFolder;
    onCalendar = "daily";
    persistent = true;
    pushUpdates = false;
    user = config.users.users.aires.name;
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
