# System options
{ pkgs, config, ... }:
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

  # Configure automatic updates
  system.autoUpgrade = {
    enable = true;
    flake = "${config.users.users.aires.home}/Development/nix-configuration";
    dates = "daily";
    allowReboot = false;
    operation = "boot"; # Don't switch, just create a boot entry
  };

  # Enable fwupd (firmware updater)
  services.fwupd.enable = true;

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
