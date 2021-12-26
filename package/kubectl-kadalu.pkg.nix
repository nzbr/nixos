{ stdenv, lib, fetchurl, writeText, python3, zip, ... }:
let
  shebang = writeText "python-shebang" ''
    #!${python3}/bin/python3
  '';
in
stdenv.mkDerivation rec
{
  pname = "kubectl-kadalu";
  version = "0.8.8";

  src = fetchurl {
    url = "https://github.com/kadalu/kadalu/releases/download/${version}/kubectl-kadalu";
    sha256 = "cfe0671e8bd72faf2400261ce4d0a6b9422f94426e54062890d349b933f3ea75";
  };

  dontUnpack = true;

  buildPhase = ''
    tail -n+2 ${src} | cat ${shebang} - > kubectl-kadalu
    chmod a+x kubectl-kadalu
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp kubectl-kadalu $out/bin/
  '';

  meta = with lib; {
    description = "glusterfs storage kubectl plugin";
    homepage = "https://kadalu.io";
    license = licenses.asl20;
    maintainers = with maintainers; [ nzbr ];
    platforms = platforms.unix;
  };
}
