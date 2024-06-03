{
  lib,
  stdenv,
  fetchurl,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "airsonic-advanced";
  version = "11.1.4-SNAPSHOT.20240531071418";

  src = fetchurl {
    url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/${version}/airsonic.war";
    sha256 = "1668a41ad75c084dd9f1d745dd3d5611c19eb286d11cf86255f15e156ffc7163";
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
