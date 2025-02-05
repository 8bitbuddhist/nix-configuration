{
  config,
  namespace,
  pkgs,
  ...
}:
{
  nix = {
    settings = {
      # Enable Flakes
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      # Set up Hevana and Lix as secondary binary caches
      substituters = [
        "https://cache.nixos.org/"
        "https://${config.${namespace}.secrets.services.binary-cache.url}"
        "https://cache.lix.systems"
      ];
      trusted-public-keys = [
        config.${namespace}.secrets.services.binary-cache.pubcert
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
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
      options = "--delete-older-than 3d";
      persistent = true;
      randomizedDelaySec = "1hour";
    };

    # Configure NixOS to use the same software channel as Flakes
    registry.nixpkgs.flake = pkgs;
    nixPath = [ "nixpkgs=${pkgs}" ];
  };
}
