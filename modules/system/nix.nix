# Core Nix configuration
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.aux.system;

  nixos-upgrade-script = pkgs.writeShellScriptBin "nixos-upgrade-script" (
    builtins.readFile ../../bin/nixos-upgrade-script.sh
  );
in
{
  options = {
    aux.system = {
      allowUnfree = lib.mkEnableOption "Allow unfree packages to install.";
      retentionPeriod = lib.mkOption {
        description = "How long to retain NixOS generations. Defaults to one month.";
        type = lib.types.str;
        default = "monthly";
      };
      nixos-upgrade-script.enable = lib.mkEnableOption "Installs the nos (nixos-upgrade-script) helper script.";
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
        allowed-users = with config.users.users; [
          root.name
          (lib.mkIf config.aux.system.users.aires.enable aires.name)
        ];

        # Avoid signature verification messages when doing remote builds
        trusted-users = with config.users.users; [
          root.name
          (lib.mkIf config.aux.system.users.aires.enable aires.name)
        ];
      };

      # Optimize the Nix store on each build
      settings.auto-optimise-store = true;
      # Enable garbage collection
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than ${cfg.retentionPeriod}";
        persistent = true;
        randomizedDelaySec = "1hour";
      };

      # Configure NixOS to use the same software channel as Flakes
      registry.nixpkgs.flake = inputs.nixpkgs;
      nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

      # Configure remote build machines
      # To enable a system to use remote build machines, add `nix.distributedBuilds = true;` to its config
      buildMachines = [
        {
          hostName = "hevana";
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

    aux.system.packages = [ (lib.mkIf cfg.nixos-upgrade-script.enable nixos-upgrade-script) ];
  };
}
