{ lib, stdenv, pkgs, zip }:
let
  py = pkgs.unstable.python3.withPackages (pythonPackages: with pkgs.unstable.python3Packages; [ panflute ]);
in
stdenv.mkDerivation rec {
  version = "1.0.1";
  pname = "pandocode";
  nativeBuildInputs = [ zip ];
  src = fetchTarball {
    url = "https://github.com/nzbr/pandocode/archive/8f021538b71029e7f9efa7d04b4dfffd4d72a0ca.tar.gz";
    sha256 = "0aa498dy287c77mcxp4bjlkpkrc7r1ibbpvnwm2c6wsmmjpsrwq9";
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
