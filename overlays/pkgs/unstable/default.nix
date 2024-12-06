{ channels, inputs, ... }:

final: prev:

{
  unstable = import inputs.nixpkgs-unstable {
    system = final.system;
    config.allowUnfree = true;
  };
}
