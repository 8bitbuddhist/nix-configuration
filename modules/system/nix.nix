# Core Nix configuration
{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.aux.system;
in
{
  options = {
    aux.system.allowUnfree = lib.mkEnableOption (lib.mdDoc "Allow unfree packages to install.");
    aux.system.retentionPeriod = lib.mkOption {
      description = "How long to retain NixOS generations. Defaults to one month.";
      type = lib.types.str;
      default = "monthly";
    };
  };
  config = {
    nixpkgs.config.allowUnfree = cfg.allowUnfree;
    nix = {
      settings = {
        # Enable Flakes
        experimental-features = [
          "nix-command"
          "flakes"
        ];

        # Use Lix instead of Nix
        substituters = [ "https://cache.lix.systems" ];
        trusted-public-keys = [ "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o=" ];

        # Only allow these users to use Nix
        allowed-users = [
          "root"
          config.users.users.aires.name
        ];

        # Avoid signature verification messages when doing remote builds
        trusted-users = [
          config.users.users.aires.name
        ] ++ lib.optionals (config.aux.system.users.gremlin.enable) [ config.users.users.gremlin.name ];
      };

      # Enable periodic nix store optimization
      optimise = {
        automatic = true;
        dates = [ "daily" ];
      };
      # Enable garbage collection
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than ${cfg.retentionPeriod}";
        persistent = true;
        randomizedDelaySec = "1hour";
      };

      # Configure NixOS to use the same software channel as Flakes
      registry = lib.mapAttrs (_: value: { flake = value; }) inputs;
      nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

      # Configure remote build machines
      # To enable remote builds for a specific host, add `nix.distributedBuilds = true;` to its config
      buildMachines = [
        {
          hostName = "dimaga";
          systems = [
            "x86_64-linux"
            "aarch64-linux"
          ];
          protocol = "ssh-ng";
          supportedFeatures = [
            "nixos-test"
            "kvm"
            "benchmark"
            "big-parallel"
          ];
        }
      ];

      # When using a builder, use its package store
      extraOptions = ''
        builders-use-substitutes = true
      '';
    };

    # Support for standard, dynamically-linked executables
    programs.nix-ld.enable = true;
  };
}
