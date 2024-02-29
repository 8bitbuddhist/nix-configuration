{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
	pname = "duplicacy-web";
	version = "1.7.2";

	src = builtins.fetchurl {
		url = "https://acrosync.com/duplicacy-web/duplicacy_web_linux_x64_${version}";
		sha256 = "88383f7fea8462539cab7757dfa167bf42e37cbc19531b9de97373bc20efd317";
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
