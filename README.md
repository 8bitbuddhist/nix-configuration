# NixOS Configuration

A full set of configuration files managed via NixOS. This project is an extension of the [Auxolotl system template](https://git.auxolotl.org/auxolotl/templates).

> [!WARNING]
> DO NOT DOWNLOAD AND RUN `nixos-rebuild` ON THIS REPOSITORY! These are my personal configuration files. I invite you to look through them, modify them, and take inspiration from them, but if you run `nixos-rebuild`, it _will completely overwrite your current system_!

## Using this repo

### Note on secrets management

Secrets are stored in a separate repo called `nix-secrets`, which is included here as a flake input. This is a poor man's secret management solution, but y'know what, it works. These "secrets" will be readable to users on the system with access to the `/nix/store/`, but for single-user systems, it's fine.

Initialize the submodule with:

```sh
git submodule update --init --recursive
```

### First-time installation

To apply the config for the first time (e.g. on a fresh install), run these commands, replacing `Shura` with the name of the host:

```sh
nix flake update
sudo nixos-rebuild switch --flake .#Shura
``` 

`nix flake update` updates the `flake.lock` file, which pins repositories to specific versions. Nix will then pull down any derivations it needs to meet the version.

> [!NOTE]
> This config installs a [Nix wrapper called nh](https://github.com/viperML/nh). Basic install/upgrade commands can be run using `nh`, but more advanced stuff should use `nixos-rebuild`.

### Running updates

All hosts are configured to run automatic daily updates (see `modules/system/system.nix`). You can disable this by adding `aux.system.services.autoUpgrade = false;` to a hosts config.

Automatic updates work by `git pull`ing the latest version of the Repo from Forgejo. This repo gets updated nightly by Haven, which updates the `flake.lock` file and pushes it back up to Forgejo. Only one host needs to do this, and you can enable this feature on a host using `aux.system.services.autoUpgrade.pushUpdates = true;`.

#### Manually updating

Run `nh` to update the system. Use the `--update` flag to update `flake.lock` as part of the process. Note that for subsequent builds, you can omit the hostname:

```sh
nh os boot --update
```

This is the equivalent of running:

```sh 
nix flake update
sudo nixos-rebuild boot --flake .
```

There are a few different actions for handling the update:

- `switch` replaces the running system immediately.
- `boot` switches to the new generation during the next reboot.
- `build` creates and caches the update without applying it.
- `test` creates the generation and switches to it, but doesn't add it to the bootloader.

#### Using Remote builds

Nix can create builds for or on remote systems, and transfer them via SSH.

##### Generating a build on a remote system

You can run a build on a remote server, then pull it down to the local system. This is called a `distributedBuild`.

> [!NOTE]
> For distributed builds, the root user on the local system needs SSH access to the build target. This is done automatically.

To enable root builds on a host, add this to its config:

```nix
nix.distributedBuilds = true;
```

For hosts where `nix.distributedBuilds` is true, this repo automatically gives the local root user SSH access to an unprivileged user on the build systems. This is configured in `nix-secrets`, but the build systems are defined in [`modules/system/nix.nix`](https://code.8bitbuddhism.com/aires/nix-configuration/src/commit/433821ef0c46f08855a041c3aa97143a954564f5/modules/system/nix.nix#L57).

##### Pushing a build to a remote system

Conversely, you can run a build on the local host, then push it to a remote system.

```sh
NIX_SSHOPTS="-o RequestTTY=force" nixos-rebuild --target-host user@example.com --use-remote-sudo switch
```

### Testing without modifying the system

If you want to test without doing a whole build, or without modifying the current system, there are a couple additional tools to try.

#### Dry builds

To quickly validate your configuration, create a dry build. This analyzes your configuration to determine whether it'll actually build:

```zsh
nixos-rebuild dry-build --flake .
```

#### Virtual machines

You can also build a virtual machine image to preview changes. The first command builds the VM, and the second runs it:

```zsh
nixos-rebuild build-vm --flake .
./result/bin/run-nixos-vm
```

> [!NOTE]
> Running the VM also creates a `.qcow2` file for data persistence. Remove this file after a while, otherwise data might persist between builds and muck things up.

### Adding a host

To add a new host:

1. Create a new folder in `hosts/`.
2. Copy `hosts/configuration.nix.template` into this folder and name it `default.nix`. 
3. Run `nixos-hardware-configuration` on the host and copy its `hardware-configuration.nix` file here. You might also want to check the `configuration.nix` generated by this command to see if there's anything you should import into your host's `default.nix`.
4. Configure `/hosts/<host>/default.nix` however you'd like.
5. Add the new host to `flake.nix`.
5. Run `nix flake update` and `nixos-rebuild boot --flake .#<Hostname>`.

## About this repository

### Layout

This config uses two main systems: Flakes, and Home-manager.

- Flakes are the entrypoint, via `flake.nix`. This is where Flake inputs and Flake-specific options get defined.
- Home-manager configs live in the `users/` folders.
- Modules are stored in `modules`. All of these files are automatically imported (except home-manager modules); you simply enable the ones you want to use, and disable the ones you don't. For example, to install Flatpak, set `aux.system.ui.flatpak.enable = true;`.
    - After adding a new module, make sure to `git add` it before running `nixos-rebuild`.

### Features

This Nix config features:

- Flakes
- Home Manager
- Automatic daily updates
- AMD, Intel, and Raspberry Pi (ARM64) hardware configurations
- Workstation and server base system configurations
- GNOME desktop environment with KDE integrations
- Boot splash screens via Plymouth
- Secure Boot and TPM
- Disk encryption via LUKS
- Custom packages and systemd services
- Flatpaks
- Default ZSH shell using Oh My ZSH
- Secrets (in a janky hacky kinda way)
