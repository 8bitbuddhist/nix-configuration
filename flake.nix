# Based on the Auxolotl template: https://github.com/auxolotl/templates
# For info on Flakes, see: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
{
  description = "Aires' system Flake";

  inputs = {
    # Import the desired Nix channel. Defaults to unstable, which uses a fully tested rolling release model.
    #   You can find a list of channels at https://wiki.nixos.org/wiki/Channel_branches
    #   To follow a different channel, replace `nixos-unstable` with the channel name, e.g. `nixos-24.05`.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Repository for Gnome triple buffering patch
    # For details, see https://wiki.nixos.org/wiki/GNOME#Dynamic_triple_buffering
    gnome-triplebuffering = {
      url = "gitlab:vanvugt/mutter/triple-buffering-v4-46?host=gitlab.gnome.org";
      flake = false;
    };

    # Home-manager support
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SecureBoot support
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";

    # Aux lib
    lib.url = "https://git.auxolotl.org/auxolotl/labs/archive/main.tar.gz?dir=lib";

    # Use Lix in place of Nix.
    #   If you'd rather use regular Nix, remove `lix-module.nixosModules.default` from the `modules` section below.
    #   To learn more about Lix, see https://lix.systems/
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=release-2.91";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flatpak support
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.4.1";

    # NixOS hardware quirks
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs =
    inputs@{
      home-manager,
      lanzaboote,
      lix-module,
      nix-flatpak,
      nixos-hardware,
      nixpkgs,
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

        Hevana = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = defaultModules ++ [
            nixos-hardware.nixosModules.common-cpu-amd-pstate
            nixos-hardware.nixosModules.common-gpu-amd
            ./hosts/Hevana
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
