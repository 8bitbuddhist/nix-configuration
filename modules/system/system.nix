# System options
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.aux.system;
in
{
  options = {
    aux.system = {
      packages = lib.mkOption {
        description = "Additional system packages to install. This is just a wrapper for environment.systemPackages.";
        type = lib.types.listOf lib.types.package;
        default = [ ];
        example = lib.literalExpression "[ pkgs.firefox pkgs.thunderbird ]";
      };

      corePackages = lib.mkOption {
        description = "Minimum set of packages to install.";
        type = lib.types.listOf lib.types.package;
        default = with pkgs; [
          # Courtesy of https://discourse.nixos.org/t/how-to-use-other-packages-binary-in-systemd-service-configuration/14363
          bash
          coreutils
          dconf
          direnv
          git
          git-crypt # Secrets management
          gnutar
          gzip
          home-manager
          openssh
          sudo
          xz.bin
        ];
      };
    };
  };
  config = {
    # Install base packages
    environment.systemPackages = cfg.corePackages ++ cfg.packages;

    services = {
      # Automatically set the timezone based on location
      automatic-timezoned.enable = true;
      geoclue2.enableDemoAgent = lib.mkForce true;

      # Enable fwupd (firmware updater)
      fwupd.enable = true;

      # Allow systemd user services to keep running after the user has logged out
      logind.killUserProcesses = false;

      # Enable disk monitoring
      smartd = {
        enable = true;
        autodetect = true;
        notifications = {
          wall.enable = true;
          mail = lib.mkIf config.aux.system.services.msmtp.enable {
            enable = true;
            mailer = "/run/wrappers/bin/sendmail";
            sender = "${config.networking.hostName}@${config.secrets.networking.domains.primary}";
            recipient = config.secrets.users.aires.email;
          };
        };
      };
    };

    # Enable visual updates
    system.activationScripts.diff = {
      supportsDryActivation = true;
      text = ''
        ${pkgs.nvd}/bin/nvd --nix-bin-dir=${pkgs.nix}/bin diff /run/current-system "$systemConfig"
      '';
    };

    # Limit logout stop timer duration to 30 seconds
    systemd.user.extraConfig = ''
      DefaultTimeoutStopSec=30s
    '';

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
  };
}
