# Based on the Auxolotl template: https://github.com/auxolotl/templates
# For info on Flakes, see: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
{
  description = "Aires' system Flake";

  inputs = {
    # Import the desired Nix channel. Defaults to unstable, which uses a fully tested rolling release model.
    #   You can find a list of channels at https://wiki.nixos.org/wiki/Nix_channels
    #   To follow a different channel, replace `nixos-unstable` with the channel name, e.g. `nixos-24.05`.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";

    # Use Lix in place of Nix.
    #   If you'd rather use regular Nix, remove `lix-module.nixosModules.default` from the `modules` section below.
    #   To learn more about Lix, see https://lix.systems/
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=release-2.90";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flatpak support
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.4.1";

    # SecureBoot support
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";

    # NixOS hardware quirks
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Home-manager support
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # "Secrets management"
    nix-secrets = {
      url = "git+file:./nix-secrets";
      flake = false;
    };
  };

  outputs =
    inputs@{
      self,
      home-manager,
      lanzaboote,
      lix-module,
      nix-flatpak,
      nixos-hardware,
      nixpkgs,
      nix-secrets,
      ...
    }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ] (system: function nixpkgs.legacyPackages.${system});

      # Define shared modules and imports
      defaultModules = [
        ./modules/autoimport.nix
        (import nix-secrets)
        lix-module.nixosModules.default
        lanzaboote.nixosModules.lanzaboote
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        {
          _module.args = {
            inherit inputs;
          };
          home-manager = {
            /*
              When running, Home Manager will use the global package cache.
              It will also back up any files that it would otherwise overwrite.
              The originals will have the extension shown below.
            */
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "home-manager-backup";
          };
        }
      ];
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-rfc-style);
      nixosConfigurations = {

        Dimaga = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = defaultModules ++ [
            nixos-hardware.nixosModules.common-cpu-intel
            ./hosts/Dimaga
          ];
        };

        Khanda = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = defaultModules ++ [
            nixos-hardware.nixosModules.microsoft-surface-pro-9
            ./hosts/Khanda
          ];
        };

        Pihole = nixpkgs.lib.nixosSystem {
          system = "aarch64-linux";
          modules = defaultModules ++ [
            nixos-hardware.nixosModules.raspberry-pi-4
            ./hosts/Pihole
          ];
        };

        Shura = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = defaultModules ++ [
            nixos-hardware.nixosModules.lenovo-legion-16arha7
            ./hosts/Shura
          ];
        };
      };
    };
}
