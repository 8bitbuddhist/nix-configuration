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

  nixos-operations-script = pkgs.writeShellScriptBin "nixos-operations-script" (
    builtins.readFile ../../bin/nixos-operations-script.sh
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
      nixos-operations-script.enable = lib.mkEnableOption "Installs the nos (nixos-operations-script) helper script.";
    };
  };
  config = lib.mkMerge [
    {
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
            (lib.mkIf config.aux.system.users.gremlin.enable gremlin.name)
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

        # When using a builder, use its package store
        extraOptions = ''
          builders-use-substitutes = true
        '';
      };

      # Support for standard, dynamically-linked executables
      programs.nix-ld.enable = true;
    }
    (lib.mkIf cfg.nixos-operations-script.enable {
      # Enable and configure NOS
      aux.system.packages = [ nixos-operations-script ];
      environment.variables."FLAKE_DIR" = config.secrets.nixConfigFolder;
    })
  ];
}
