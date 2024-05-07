{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
  pname = "duplicacy-web";
  version = "1.8.0";

  src = builtins.fetchurl {
    url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_x64_${version}";
    sha256 = "f0b4d4c16781a6ccb137f161df9de86574e7a55660c582682c63062e26476c4a";
  };

  doCheck = false;

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/duplicacy-web
    chmod a+x $out/duplicacy-web
  '';

  meta = with lib; {
    homepage = "https://duplicacy.com";
    description = "A new generation cloud backup tool";
    platforms = platforms.linux;
    license = licenses.unfreeRedistributable;
  };
}
