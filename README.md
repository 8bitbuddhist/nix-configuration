# NixOS Configuration

A full set of configuration files managed via NixOS. This project uses the [Snowfall library](https://snowfall.org/guides/lib/quickstart).

> [!NOTE]
> Are you new to NixOS? Hi, hello, and welcome! This repository probably won't make much sense to you 😅 If you're looking for a good beginner configuration or template, check out https://github.com/Misterio77/nix-starter-configs
>
> Warning: DO NOT DOWNLOAD AND RUN `nixos-rebuild` ON THIS REPOSITORY! These are my personal configuration files. I invite you to look through them, modify them, and take inspiration from them, but if you run `nixos-rebuild`, it _will completely overwrite your current system_!

## Using this repo

### Note on secrets management

Secrets are managed using [transcrypt](https://github.com/elasticdog/transcrypt). To unlock the repo, use `transcrypt -c [cipher] -p '[password]'`. Transcrypt will transparently encrypt/decrypt files stored in `modules/nixos/secrets` going forward. You can get the cipher and password from a host with transcrypt already configured by running `transcrypt --display`.

> [!NOTE]
> This is a poor man's secret management solution. If you use this, your secrets will be world-readable in the `/nix/store/`.

### First-time installation

When installing on a brand new system, partition the main drive into two partitions: a `/boot` partition, and a LUKS partition. Then, run `bin/format-drives.sh --root [root partition] --luks [luks partition]` (the script will request sudo privileges):

```sh
./bin/format-drives.sh --boot /dev/nvme0n1p1 --luks /dev/nvme0n1p2
```

Next, set up the host's config in the `systems/[architecture]` folder by copying `default.nix.template` and `hardware-configuration.nix.template` into a new folder named after the hostname. Running `format-drives.sh` also generates a `hardware-configuration.nix` file you can use.

If necessary, import modules by adding the host to `flake.nix` under the `outputs.systems.hosts` section.

Finally, run the NixOS installer, replacing `host` with your actual hostname:

```sh
sudo nixos-install --verbose --root /mnt --flake .#host --no-root-password
```

> [!TIP]
> This config installs a nixos-rebuild wrapper called `nos` (NixOS Operations Script) that handles pulling and pushing changes to your configuration repository via git. For more info, run `nixos-operations-script --help`.

### Running updates

To update a system, run `nixos-operations-script` (or just `nos`). To commit updates back to the repo, use `nos --update`. Do not run this script as root - it will automatically request sudo permissions as needed.

#### Automatic updates

To enable automatic updates for a host, set `config.${namespace}.services.autoUpgrade = true;`. You can configure the autoUpgrade module with additional settings, e.g.:

```nix
services.autoUpgrade = {
  enable = true;
  configDir = config.${namespace}.secrets.nixConfigFolder;
  onCalendar = "daily";
  user = config.users.users.aires.name;
};
```

Automatic updates work by running `nos`. There's an additional `pushUpdates` option that, when enabled, updates the `flake.lock` file and pushes it back up to the Git repository. Only one host needs to do this (in this case, it's [Hevana](./systems/x86_64-linux/Hevana)), but you can safely enable it on multiple hosts as long as they use the same repository and update at different times.

#### Manually updating

Run `nos` to update the system. Use the `--update` flag to update `flake.lock` as part of the process. For the first build, you'll need to specify the path to your `flake.nix` file and the hostname using `nos --hostname my_hostname --flake /path/to/flake.nix`.

After the first build, you can omit the hostname and path:

```sh
nos
```

This is the equivalent of running:

```sh
cd [flake dir]
git pull
nix flake update --commit-lock-file
git push
sudo nixos-rebuild switch --flake .
```

There are a few different actions for handling the update:

- `switch` replaces the running system immediately.
- `boot` switches to the new generation during the next reboot.
- `build` creates and caches the update without applying it.
- `test` creates the generation and switches to it, but doesn't add it to the bootloader.

#### Using Remote builds

Nix can create builds for or on remote systems, and transfer them via SSH.

##### Generating a build on a remote system

You can run a build on a remote server by using `--build-host`:

```sh
nixos-rebuild build --flake . --build-host [remote hostname]
```

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

## About this repository

This config uses the [Snowfall lib](https://snowfall.org/), along with some default options and settings for common software. It features:

- Flakes
- Home Manager
- Automatic daily updates
- AMD, Intel, and Raspberry Pi (ARM64) hardware configurations
- Support for various GUIs and desktop environments including Gnome, KDE, XFCE, and Hyprland
- Boot splash screens via Plymouth
- Secure Boot support via Lanzaboote
- Disk encryption via LUKS with TPM auto-unlocking
- Custom packages and systemd services
- Flatpaks
- Default ZSH shell using Oh My ZSH
- Secrets (sorta - using Transcrypt)
