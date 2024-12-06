{
  lib,
}:
{
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
}
