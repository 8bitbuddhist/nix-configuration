{
  lib,
  stdenv,
  fetchurl,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "airsonic-advanced";
  version = "11.1.4-SNAPSHOT.20240628143437";

  src = fetchurl {
    url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/${version}/airsonic.war";
    sha256 = "fde2c921e26cf536405118c5114a2f42fe87ff0a019852f21c80f4c68a2431ee";
  };

  buildCommand = ''
    mkdir -p "$out/webapps"
    cp "$src" "$out/webapps/airsonic.war"
  '';

  passthru.tests = {
    airsonic-starts = nixosTests.airsonic;
  };

  meta = {
    description = "Free, web-based media streamer providing ubiquitous access to your music.";
    homepage = "https://github.com/kagemomiji/airsonic-advanced/";
    sourceProvenance = [ lib.sourceTypes.binaryBytecode ];
    license = lib.licenses.gpl3;
    platforms = lib.platforms.all;
  };
}
