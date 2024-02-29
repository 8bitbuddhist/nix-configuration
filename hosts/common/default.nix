{ lib, ... }: 
let
  # Fetch secrets
  # IMPORTANT: Make sure this repo exists on the filesystem first!
  nix-secrets = builtins.fetchGit {
  	url = "/home/aires/Development/nix-configuration/nix-secrets";
    ref = "main";
    rev = "75076eba4de5d8539cc1a2a85bf3924c9ae4b7b9";
  };
in{
  imports = [
    ../../modules
    "${nix-secrets}/default.nix"
  ];
}
