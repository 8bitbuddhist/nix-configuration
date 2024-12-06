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
    builtins.readFile ../../../../bin/nixos-operations-script.sh
  );
in
{
  options = {
    aux.system = {
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
      nix = {
        extraOptions = ''
          # Ensure we can still build when secondary caches are unavailable
          fallback = true
        '';

        settings = {
          # Enable Flakes
          experimental-features = [
            "nix-command"
            "flakes"
          ];

          # Set up secondary binary caches for Lix and Hevana
          substituters = [
            "https://cache.lix.systems"
            "https://${config.secrets.services.binary-cache.url}"
          ];
          trusted-public-keys = [
            "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
            config.secrets.services.binary-cache.pubcert
          ];

          # Authentication for Hevana's binary cache
          netrc-file =
            with config.secrets.services.binary-cache;
            pkgs.writeText "netrc" ''
              machine ${url} login ${auth.username} password ${auth.password}
            '';

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
