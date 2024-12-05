# Based on the Auxolotl template: https://github.com/auxolotl/templates
# For info on Flakes, see: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
{
  description = "Aires' system Flake";

  inputs = {
    # Import the desired Nix channel. Defaults to unstable, which uses a fully tested rolling release model.
    #   You can find a list of channels at https://wiki.nixos.org/wiki/Channel_branches
    #   To follow a different channel, replace `nixos-unstable` with the channel name, e.g. `nixos-24.05`.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Power management via auto-cpufreq
    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq/v2.4.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Home-manager support
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SecureBoot support
    lanzaboote.url = "github:nix-community/lanzaboote/v0.4.1";

    # Use Lix in place of Nix.
    #   If you'd rather use regular Nix, remove `lix-module.nixosModules.default` from the `modules` section below.
    #   To learn more about Lix, see https://lix.systems/
    lix-module = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=release-2.91";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Flatpak support
    nix-flatpak.url = "github:gmodena/nix-flatpak/v0.5.0";

    # NixOS hardware quirks
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Snowfall - a unified configuration manager for NixOS
    # Quickstart guide: https://snowfall.org/guides/lib/quickstart/
    # Jake's reference config: https://github.com/jakehamilton/config
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs:
    let
      lib = inputs.snowfall-lib.mkLib {
        inherit inputs;

        # Root dir for flake.nix
        src = ./.;

        # Configure Snowfall
        snowfall = {
          # Choose a namespace to use for your flake's packages, library, and overlays.
          namespace = "Sapana";

          # Add flake metadata that can be processed by tools like Snowfall Frost.
          meta = {
            # A slug to use in documentation when displaying things like file paths.
            name = "aires-flake";

            # A title to show for your flake, typically the name.
            title = "Aires' Flake";
          };
        };
      };
    in
    lib.mkFlake {
      # Configure Nix channels
      channels-config.allowUnfree = true;

      # Define systems
      systems = {
        # Modules to import for all systems
        modules.nixos = with inputs; [
          ./modules/autoimport.nix
          auto-cpufreq.nixosModules.default
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

        # Individual host configurations
        hosts = {
          Dimaga.modules = with inputs; [
            nixos-hardware.nixosModules.common-cpu-intel
            ./hosts/Dimaga
          ];

          Hevana.modules = with inputs; [
            nixos-hardware.nixosModules.common-cpu-amd-pstate
            nixos-hardware.nixosModules.common-gpu-amd
            ./hosts/Hevana
          ];

          Khanda.modules = with inputs; [
            nixos-hardware.nixosModules.microsoft-surface-pro-9
            ./hosts/Khanda
          ];

          Pihole.modules = with inputs; [
            nixos-hardware.nixosModules.raspberry-pi-4
            ./hosts/Pihole
          ];

          Shura.modules = with inputs; [
            nixos-hardware.nixosModules.lenovo-legion-16arha7
            ./hosts/Shura
          ];
        };
      };

      # Use treefmt to format project repo
      outputs-builder = channels: {
        formatter = (inputs.treefmt-nix.lib.evalModule channels.nixpkgs ./treefmt.nix).config.build.wrapper;
      };
    };
}
