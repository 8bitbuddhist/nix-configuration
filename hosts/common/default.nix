{ lib, ... }: 
let
  # Fetch secrets.
  # NOTE: This requires access to a private repo. Make sure you generate the build as `aires`, then switch to it as root.
  nix-secrets = builtins.fetchGit {
    url = "ssh://git@code.8bitbuddhism.com:22222/andre/nix-secrets.git";
    ref = "main";
    rev = "a5b902f720e1e51df0f688b29d449c910468fb28";
  };
in{
  imports = [
    ../../modules
    "${nix-secrets}/default.nix"
  ];
}