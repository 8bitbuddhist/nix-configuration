# Core Nix configuration
{
  config,
  inputs,
  lib,
  pkgs,
  namespace,
  system,
  ...
}:

let
  cfg = config.${namespace}.nix;

  nixos-operations-script = pkgs.writeShellScriptBin "nixos-operations-script" (
    builtins.readFile (lib.snowfall.fs.get-file "bin/nixos-operations-script.sh")
  );
in
{
  options.${namespace}.nix = {
    retention = lib.mkOption {
      description = "How long to retain NixOS generations. Defaults to two weeks.";
      type = lib.types.str;
      default = "14d";
    };
    nixos-operations-script.enable = lib.mkEnableOption "Installs the nos (nixos-operations-script) helper script.";
  };
  config = lib.mkMerge [
    {
      nix = {
        # Ensure we can still build when secondary caches are unavailable
        extraOptions = ''
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
            "https://${config.${namespace}.secrets.services.binary-cache.url}"
          ];
          trusted-public-keys = [
            "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
            config.${namespace}.secrets.services.binary-cache.pubcert
          ];

          # Authentication for Hevana's binary cache
          netrc-file =
            with config.${namespace}.secrets.services.binary-cache;
            pkgs.writeText "netrc" ''
              machine ${url} login ${auth.username} password ${auth.password}
            '';

          # Only allow these users to use Nix
          allowed-users = with config.users.users; [
            root.name
            (lib.mkIf config.${namespace}.users.aires.enable aires.name)
            (lib.mkIf config.${namespace}.users.gremlin.enable gremlin.name)
          ];

          # Avoid signature verification messages when doing remote builds
          trusted-users = with config.users.users; [
            root.name
            (lib.mkIf config.${namespace}.users.aires.enable aires.name)
          ];
        };

        # Optimize the Nix store on each build
        settings.auto-optimise-store = true;
        # Enable garbage collection
        gc = {
          automatic = true;
          dates = "weekly";
          options = "--delete-older-than ${cfg.retention}";
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
      ${namespace}.packages = [ nixos-operations-script ];
      environment.variables."FLAKE_DIR" = config.${namespace}.secrets.nixConfigFolder;
    })
  ];
}
