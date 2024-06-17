{
  lib,
  stdenv,
  fetchurl,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "airsonic-advanced";
  version = "11.1.4-SNAPSHOT.20240616141843";

  src = fetchurl {
    url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/${version}/airsonic.war";
    sha256 = "57877d56ab913974cfb5b5f3f8d2e2df4b289e7cde494f8766b7e35a93f82fbe";
  };

  buildCommand = ''
    mkdir -p "$out/webapps"
    cp "$src" "$out/webapps/airsonic.war"
  '';

  passthru.tests = {
    airsonic-starts = nixosTests.airsonic;
  };

  meta = with lib; {
    description = "Free, web-based media streamer providing ubiquitous access to your music.";
    homepage = "https://github.com/kagemomiji/airsonic-advanced/";
    sourceProvenance = with sourceTypes; [ binaryBytecode ];
    license = lib.licenses.gpl3;
    platforms = platforms.all;
    maintainers = with maintainers; [ disassembler ];
  };
}
