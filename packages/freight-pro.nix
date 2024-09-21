{ stdenv, pkgs }:

stdenv.mkDerivation rec {
  pname = "freight-pro-fonts";
  version = "20240828T164047Z-001";
  nativeBuildInputs = [ pkgs.unzip ];
  buildInputs = [ pkgs.unzip ];

  src = ../modules/secrets/Freight-20240828T164047Z-001.zip;

  unpackPhase = ''
    runHook preUnpack
    ${pkgs.unzip}/bin/unzip $src

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 ${pname}-${version}/*.otf -t $out/share/fonts/opentype

    runHook postInstall
  '';
}
