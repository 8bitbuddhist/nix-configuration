{
  lib,
  stdenv,
  fetchurl,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "airsonic-advanced";
  version = "11.1.4-SNAPSHOT.20240628001308";

  src = fetchurl {
    url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/${version}/airsonic.war";
    sha256 = "7fd7935b57a716754cf4008a2b4376a0f2b762deec2a56bb6e5481b5ad0a529f";
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
  };
}
