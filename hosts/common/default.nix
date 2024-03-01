{ lib, ... }: 
let
  # Fetch secrets
  # IMPORTANT: Make sure this repo exists on the filesystem first!
  nix-secrets = builtins.fetchGit {
  	url = "/home/aires/Development/nix-configuration/nix-secrets";
    ref = "main";
    rev = "7e6dd41b5a89a1ff2ead22bf69e5b82b585c0fa2";
  };
in{
  imports = [
    ../../modules
    "${nix-secrets}/default.nix"
  ];
}
