# Based on the Auxolotl template: https://github.com/auxolotl/templates
# For info on Flakes, see: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
{
  description = "Aires' system Flake";

  inputs = {
    # Track base packagese
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-24.05";

    # Replace Nix with Lix: https://lix.systems/
    lix = {
      url = "git+https://git@git.lix.systems/lix-project/lix?ref=refs/tags/2.90-beta.1";
      flake = false;
    };
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module";
      inputs.lix.follows = "lix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SecureBoot support
    lanzaboote.url = "github:nix-community/lanzaboote/v0.3.0";

    # Flatpak support
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.4.1";

    # Hardware configurations
    nixos-hardware.url = "git+https://code.8bitbuddhism.com/aires/nixos-hardware?ref=master";
    #nixos-hardware.url = "git+https://github.com/NixOS/nixos-hardware?ref=master";

    # Home-manager
    home-manager = {
      url = "github:nix-community/home-manager?ref=release-24.05";
      inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list where available
    };

    # "Secrets management"
    nix-secrets = {
      url = "git+ssh://forgejo@code.8bitbuddhism.com/aires/nix-secrets";
      flake = false;
    };

    # TODO: Add Disko - https://github.com/nix-community/disko
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      lanzaboote,
      nix-flatpak,
      home-manager,
      nixos-hardware,
      lix-module,
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
      config.allowUnfree = true;

      # Define shared modules and imports
      defaultModules = [
        {
          _module.args = {
            inherit inputs self;
          };
        }
        ./modules/autoimport.nix
        (import nix-secrets)
        lix-module.nixosModules.default
        lanzaboote.nixosModules.lanzaboote
        nix-flatpak.nixosModules.nix-flatpak
        home-manager.nixosModules.home-manager
        {
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
            nixos-hardware.nixosModules.common-gpu-intel
            ./hosts/Dimaga
          ];
        };

        Haven = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = defaultModules ++ [
            nixos-hardware.nixosModules.common-cpu-amd-pstate
            nixos-hardware.nixosModules.common-gpu-amd
            ./hosts/Haven
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
