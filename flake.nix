# For info on Flakes, see: https://nixos-and-flakes.thiscute.world/nixos-with-flakes/nixos-with-flakes-enabled

{
	description = "Aires' system Flake";
	
	inputs = {
		# Track base packages against Nix unstable
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		# SecureBoot support
		lanzaboote.url = "github:nix-community/lanzaboote/v0.3.0";

		# Flatpak support
		nix-flatpak.url = "github:gmodena/nix-flatpak/v0.3.0";

		# Hardware configurations
		nixos-hardware.url = "github:NixOS/nixos-hardware/master";

		# Home-manager
		home-manager = {
			url = "github:nix-community/home-manager/master";
			inputs.nixpkgs.follows = "nixpkgs"; # Use system packages list where available
		};
	};

	outputs = inputs@{ self, nixpkgs, lanzaboote, nix-flatpak, home-manager, nixos-hardware, ... }:
		let 
			inherit (self) outputs;
			inherit (nixpkgs) lib;
			systems = [ "x86_64-linux" "aarch64-linux" ];
			forEachSystem = f: lib.genAttrs systems (sys: f pkgsFor.${sys});
			pkgsFor = lib.genAttrs systems (system: import nixpkgs {
				inherit system;
				config.allowUnfree = true;
			});
			
			# Define shared modules and imports
			defaultModules = {
				base = [
					{ _module.args = { inherit inputs; }; }
					lanzaboote.nixosModules.lanzaboote
					nix-flatpak.nixosModules.nix-flatpak
					home-manager.nixosModules.home-manager {
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
			};
		in {
			nixosConfigurations = {
				Dimaga = nixpkgs.lib.nixosSystem {
					system = "x86_64-linux";
					modules = defaultModules.base ++ [
						./hosts/Dimaga
					];
				};

				Haven = nixpkgs.lib.nixosSystem {
					system = "x86_64-linux";
					modules = defaultModules.base ++ [
						./hosts/Haven
					];
				};

				Pihole = nixpkgs.lib.nixosSystem {
					system = "aarch64-linux";
					modules = defaultModules.base ++ [
						nixos-hardware.nixosModules.raspberry-pi-4
						./hosts/Pihole
					];
				};

				Shura = nixpkgs.lib.nixosSystem {
					system = "x86_64-linux";
					modules = defaultModules.base ++ [
						./hosts/Shura
					];
				};
			};
		};
	}
