{ lib, ... }: 
let
  # Fetch secrets.
  # NOTE: This requires access to a private repo. Make sure you generate the build as `aires`, then switch to it as root.
  nix-secrets = builtins.fetchGit {
    url = "ssh://git@code.8bitbuddhism.com:22222/andre/nix-secrets.git";
    ref = "main";
    rev = "75076eba4de5d8539cc1a2a85bf3924c9ae4b7b9";
  };
in{
  imports = [
    ../../modules
    "${nix-secrets}/default.nix"
  ];
}
