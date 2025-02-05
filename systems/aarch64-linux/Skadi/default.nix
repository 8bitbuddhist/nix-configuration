{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    modules/ssh
  ];

  environment.packages = with pkgs; [
    # User-facing stuff that you really really want to have
    gawk
    vim # or some other editor, e.g. nano or neovim
    nano

    # Some common stuff that people expect to have
    procps
    killall
    diffutils
    findutils
    utillinux
    tzdata
    hostname
    man
    gnugrep
    gnupg
    gnused
    gnutar
    bzip2
    gzip
    xz
    zip

    git
    zellij
    zsh
    openssh
    nixfmt-rfc-style

    # Required for Transcrypt
    transcrypt
    openssl
    xxd
  ];

  # Backup etc files instead of failing to activate generation if a file already exists in /etc
  environment.etcBackupExtension = ".bak";

  # Read the changelog before changing this value
  system.stateVersion = "24.05";

  # Set up nix for flakes
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  # Set your time zone
  #time.timeZone = "Europe/Berlin";

  home-manager = {
    backupFileExtension = "home-manager.bak";
    useGlobalPkgs = true;
    config = ./homes;
  };

  user.shell = "${lib.getExe pkgs.zsh}";
}
