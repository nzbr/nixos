{ stdenv
, lib
, vlang
, ...
}: stdenv.mkDerivation rec {
  name = "auto-brightness";
  src = ./.;

  nativeBuildInputs = [
    vlang
  ];

  buildPhase = ''
    export HOME=$TMPDIR
    # v -cc ${lib.getExe stdenv.cc} -prod -o auto-brightness .
    # Some weird stuff happens in the json parse when using -prod
    v -cc ${lib.getExe stdenv.cc} -o auto-brightness .
  '';

  installPhase = ''
    install -Dm755 ./auto-brightness $out/bin/auto-brightness
  '';

  dontStrip = true;
}
