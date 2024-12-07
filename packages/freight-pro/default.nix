{
  lib,
  stdenv,
  pkgs,
}:

stdenv.mkDerivation rec {
  pname = "freight-pro-fonts";
  version = "20240828T164047Z-001";
  nativeBuildInputs = [ pkgs.unzip ];
  buildInputs = [ pkgs.unzip ];

  src = lib.snowfall.fs.get-file "modules/nixos/secrets/Freight-20240828T164047Z-001.zip";

  unpackPhase = ''
    runHook preUnpack
    ${pkgs.unzip}/bin/unzip $src

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -m 644 -D Freight-${version}/*.otf -t $out/share/fonts/opentype

    runHook postInstall
  '';
}
