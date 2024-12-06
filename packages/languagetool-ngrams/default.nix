# For a packaging example, see https://github.com/Janik-Haag/nix-languagetool-ngram/blob/main/ngram-template.nix
{
  pkgs,
  lib,
  fetchzip,
}:

pkgs.stdenv.mkDerivation rec {
  pname = "languagetool-ngram-en";
  version = "20150817";
  language = "en";

  src = fetchzip {
    url = "https://languagetool.org/download/ngram-data/ngrams-${language}-${version}.zip";
    sha256 = "v3Ym6CBJftQCY5FuY6s5ziFvHKAyYD3fTHr99i6N8sE=";
  };

  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  installPhase = ''
    mkdir -p $out/share/languagetool/ngrams
    ln -s $src $out/share/languagetool/ngrams/${language}
  '';

  meta = with lib; {
    homepage = "https://dev.languagetool.org/finding-errors-using-n-gram-data.html";
    description = "LanguageTool can make use of large n-gram data sets to detect errors with words that are often confused, like their and there.";
    platforms = platforms.linux;
    license = licenses.cc-by-sa-40;
  };
}
