# NixOS Configuration

A full set of configuration files managed via NixOS. This project follows the general structure of https://github.com/tiredofit/nixos-config

## Running

### Note on secrets management

Secrets are stored in a separate repo called `nix-secrets`, which is included here as a submodule. It gets pulled into the main config via `hosts/common/default.nix`. This is a poor man's secret management solution, but y'know what, it works. These "secrets" will be readable to users on the system with access to the `/nix/store/`, but for single-user systems, it's fine.

Initialize the submodule with:

```sh
git submodule update --init --recursive
```

### Applying the configuration

To apply the config for the first time (e.g. on a fresh install), run this command, replacing `Shura` with the name of the host:

```sh
sudo nixos-rebuild switch --flake .#Shura
```

For subsequent builds, you can omit the hostname:

```sh
sudo nixos-rebuild switch --flake .
```

`switch` replaces the running system immediately, or you can use `boot` to only apply the switch during the next reboot. After applying the build at least once (or setting the hostname manually), you can omit the hostname from the command and just run `nixos-rebuild build --flake .`

### Testing

To quickly validate the configuration, create a dry build. This builds the config without actually adding it to the system:

```zsh
nixos-rebuild dry-build --flake .
```

To preview changes in a virtual machine, use this command to create a virtual machine image (remove the .qcow2 image after a while, otherwise data persistence might mess things up):

```zsh
nixos-rebuild build-vm --flake .
```

### Updating

`flake.lock` locks the version of any packages/modules used. To update them, run `nix flake update` first:

```zsh
nix flake update && sudo nixos-rebuild switch --flake .
```

Home-manager also installs a ZSH alias, so you can just run `update` or `upgrade` for the same effect.

## Layout

This config uses two systems: Flakes, and Home-manager.

- Flakes are the entrypoint, via `flake.nix`. This is where you include Flake modules and define Flake-specific options.
- Home-manager configs live in the `users/` folders. Each user gets its own `home-manager.nix` file too.
- Modules are stored in `modules`. All of these files are imported, and you enable the ones you want to use. For example, to install Flatpak, set `host.ui.flatpak.enable = true;`.
    - After adding a new module, make sure to `git add` it _and_ `import` it in `default.nix`.

### Adding a host

When adding a host:

1. Create its config in `hosts/hostname/<hostname>.nix`. Add its `hardware-configuration.nix` here too.
2. Reference a profile from `profiles/`. This sets up its base configuration.
3. Include user accounts from `users`.
4. Add any host-specific options, 
5. Import it in `/hosts/default.nix`.
6. Run `nixos-rebuild`.

## Features

This Nix config features:

- Flakes
- Home Manager
- AMD and Intel hardware configurations
- Workstation and server base system configurations
- GNOME Desktop environment and KDE integrations
- Boot splash screens via Plymouth
- Secure Boot
- Disk encryption via LUKS
- Custom packages and systemd services (Duplicacy)
- Flatpaks
- Per-user configurations
- Default ZSH shell using Oh My ZSH
- Secrets (in a janky hacky kinda way)