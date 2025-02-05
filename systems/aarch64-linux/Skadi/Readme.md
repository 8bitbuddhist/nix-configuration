# nix-on-droid

Run Nix on an Android device! Includes Home Manager and Flakes.

Main project:  https://github.com/nix-community/nix-on-droid/
Project wiki:  https://github.com/nix-community/nix-on-droid/wiki
Documentation: https://nix-community.github.io/nix-on-droid/

## How to use

1. Install the nix-on-droid app from F-Droid: https://f-droid.org/packages/com.termux.nix
2. Copy this folder to your phone. On the phone, move the folder from regular storage to the storage device created by nix-on-droid. This will place it into the home directory.
3. In the app, run `nix-on-droid switch --flake .`.

To start an SSH session, run `sshd-start`. This will only work if you rebuild first.
