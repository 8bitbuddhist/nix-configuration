{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
  pname = "duplicacy-web";
  version = "1.8.3";

  src = builtins.fetchurl {
    url = "https://acrosync.com/${pname}/duplicacy_web_linux_x64_${version}";
    sha256 = "9cdcaa875ae5fc0fcf93941df3a5133fb3c3ff92c89f87babddc511ba6dd7ef8";
  };

  doCheck = false;

  dontUnpack = true;

  installPhase = ''
    install -D $src $out/duplicacy-web
    chmod a+x $out/duplicacy-web
  '';

  meta = {
    homepage = "https://duplicacy.com";
    description = "A new generation cloud backup tool";
    platforms = lib.platforms.linux;
    license = lib.licenses.unfreeRedistributable;
  };
}
