{
  lib,
  stdenv,
  fetchurl,
  nixosTests,
}:

stdenv.mkDerivation rec {
  pname = "airsonic-advanced";
  version = "11.1.4-SNAPSHOT.20240518150716";

  src = fetchurl {
    url = "https://github.com/kagemomiji/airsonic-advanced/releases/download/${version}/airsonic.war";
    sha256 = "f4274fadd0acfe7f21d04e34ebb158238d8aaac06c0c76f6a4bf3d2d5bb41156";
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
