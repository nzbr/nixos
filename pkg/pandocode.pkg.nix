{ lib, fetchFromGitHub, stdenv, pkgs, zip }:
let
  py = pkgs.unstable.python3.withPackages (pythonPackages: with pkgs.unstable.python3Packages; [ panflute ]);
in
stdenv.mkDerivation rec {
  version = "1.0.1";
  name = "pandocode-${version}";
  nativeBuildInputs = [ zip ];
  src = fetchFromGitHub {
    owner = "nzbr";
    repo = "pandocode";
    rev = "2e19dd35e55ec50c2fc4a52a4e5041c5d93b76dc";
    sha256 = "I25ueMVJcVbauwblw0E10EccfRLAUAB/1ashkf01ixk=";
  };
  format = "other";
  doCheck = false;
  buildPhase = ''
    make PREFIX=$out \
      PY=${py}/bin/python3 \
      PYLINT=true \
      pandocode.pyz.zip

    echo "#!${py}/bin/python3" | cat - pandocode.pyz.zip > pandocode
  '';
  installPhase = ''
    install -D -m 755 pandocode $out/bin/pandocode
  '';
  meta = with lib; {
    description = "pandocode is a pandoc filter that converts Python (-like) code to LaTeX-Pseudocode";
    homepage = "https://github.com/nzbr/pandocode";
    license = licenses.isc;
    platforms = platforms.linux ++ platforms.darwin;
  };

}
