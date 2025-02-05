# Uses Snowfall: https://snowfall.org/
# For info on Flakes, see: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled
{
  description = "Aires' system Flake";

  inputs = {
    # Import the desired Nix channel. Defaults to unstable, which uses a fully tested rolling release model.
    #   You can find a list of channels at https://wiki.nixos.org/wiki/Channel_branches
    #   To follow a different channel, replace `nixos-unstable` with the channel name, e.g. `nixos-24.05`.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Blocklist for AI bots
    ai-blocklist = {
      url = "github:ai-robots-txt/ai.robots.txt";
      flake = false;
    };

    # Flatpak support
    flatpak.url = "github:gmodena/nix-flatpak/latest";

    # Home-manager support
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # SecureBoot support
    lanzaboote.url = "github:nix-community/lanzaboote/master";

    # Use Lix in place of Nix.
    #   If you'd rather use regular Nix, remove `lix-module.nixosModules.default` from the `modules` section below.
    #   To learn more about Lix, see https://lix.systems/
    lix = {
      url = "git+https://git.lix.systems/lix-project/nixos-module?ref=stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS hardware quirks
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    # Snowfall lib: https://snowfall.org/guides/lib/quickstart/
    # Jake's reference config: https://github.com/jakehamilton/config
    snowfall-lib = {
      url = "github:snowfallorg/lib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Code formatter
    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Support for nix-on-droid
    nixpkgs-2405.url = "github:nixos/nixpkgs/nixos-24.05";
    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-2405";
    };

    # Extra packages for nix-on-droid
    nixdroidpkgs = {
      url = "github:horriblename/nixdroidpkgs";
      inputs.nixpkgs.follows = "nixpkgs-2405";
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
      # Allow unfree packages in Nix config
      channels-config.allowUnfree = true;

      # Define nix-on-droid
      nixOnDroidConfigurations.default = inputs.nix-on-droid.lib.nixOnDroidConfiguration {
        # Pass Snowfall args into nix-on-droid
        extraSpecialArgs = {
          namespace = lib.snowfall.namespace;
        };
        pkgs = import inputs.nixpkgs-2405 {
          system = "aarch64-linux";
        };
        modules = [
          ./systems/aarch64-linux/Skadi
          {
            environment.packages = with inputs.nixdroidpkgs.packages.aarch64-linux; [
              termux-auth
              #openssh # Unable to build due to outdated patches
            ];
          }
        ];
      };

      # Define NixOS systems
      systems = {
        # Modules to import for all systems
        modules.nixos = with inputs; [
          lix.nixosModules.default
          lanzaboote.nixosModules.lanzaboote
          flatpak.nixosModules.nix-flatpak
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
          Hevana.modules = with inputs; [
            nixos-hardware.nixosModules.common-cpu-amd-pstate
            nixos-hardware.nixosModules.common-gpu-amd
          ];

          Khanda.modules = with inputs; [
            nixos-hardware.nixosModules.microsoft-surface-pro-9
          ];

          Pihole.modules = with inputs; [
            nixos-hardware.nixosModules.raspberry-pi-4
          ];

          Shura.modules = with inputs; [
            nixos-hardware.nixosModules.lenovo-legion-16arha7
          ];
        };
      };

      # Define .nix file templates
      templates = {
        module.description = "Template for creating a new module.";
        systems.description = "Template for defining a new system.";
      };

      # Use treefmt to format project repo
      outputs-builder = channels: {
        formatter = (inputs.treefmt.lib.evalModule channels.nixpkgs ./treefmt.nix).config.build.wrapper;
      };
    };
}
