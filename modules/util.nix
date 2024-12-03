# Utility and helper functions
{
  lib,
  ...
}:

{
  nixpkgs.overlays = [
    (final: _prev: {
      # Define custom functions using 'pkgs.util'
      util = {
        # Parses the domain from a URI
        getDomainFromURI =
          url:
          let
            parsedURL = (lib.strings.splitString "." url);
          in
          builtins.concatStringsSep "." [
            (builtins.elemAt parsedURL 1)
            (builtins.elemAt parsedURL 2)
          ];
      };
    })
  ];
}
