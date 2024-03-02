{ lib, ... }: 
let
  # Fetch secrets
  # IMPORTANT: Make sure this repo exists on the filesystem first!
  nix-secrets = builtins.fetchGit {
  	url = "/home/aires/Development/nix-configuration/nix-secrets";
    ref = "main";
    rev = "55fc814d477d956ab885e157f24c2d43f433dc7a";
  };
in{
  imports = [
    ../../modules
    "${nix-secrets}/default.nix"
  ];
}
